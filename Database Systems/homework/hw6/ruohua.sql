DROP FUNCTION IF EXISTS recommendation(time,time,varchar,int,float,float,float);
DROP FUNCTION IF EXISTS recommendation_helper(time,time,varchar,int,float,float,float);

CREATE OR REPLACE FUNCTION
    recommendation_helper(fromtime time
               , totime time
               , inputstation varchar
               , topk int
	       , w1 float, w2 float, w3 float) RETURNS VARCHAR AS $$
BEGIN
   RETURN 'Inputs: '||fromtime::varchar(5)||' '||totime::varchar(5)||' / '||inputstation||' / '||topk::varchar||' / '||w1::varchar||' '||w2::varchar||' '||w3::varchar ;
END ;
$$ LANGUAGE plpgsql ;

DROP TABLE IF EXISTS songsimilarity;

CREATE TABLE songsimilarity(
    songid       int
    , songname   text
    , artistname text
    , songscore  float
) ;    


CREATE OR REPLACE FUNCTION
    recommendation(fromtime time
               , totime time
               , inputstation varchar
               , topk int
	       , w1 float, w2 float, w3 float)
    RETURNS SETOF songsimilarity AS $$
DECLARE
   myrow songsimilarity%rowtype ;
BEGIN
   
    DROP TABLE IF EXISTS songsplayed;
        CREATE TABLE songsplayed AS 
            (
            SELECT DISTINCT p.songid as songid
            FROM playedonradio p
            WHERE  inputstation = p.station and fromtime <= p.playedtime::TIME and totime >= p.playedtime::TIME
            );

    CREATE OR REPLACE FUNCTION gs(id BIGINT, fromtime time, totime time, inputstation varchar)
    RETURNS FLOAT AS $gs$
    DECLARE
        ret float;
        myrow RECORD;
    BEGIN
        
        DROP TABLE IF EXISTS genre_score;
        CREATE TABLE genre_score AS 
            (
            SELECT sg.genre as genre, COUNT(sp.songid) as score
            FROM songsplayed sp, song_genre sg 
            WHERE sp.songid = sg.songid
            GROUP BY genre
            );

        
        ret = COALESCE((SELECT SUM(gs.score)
        FROM song_genre g, genre_score gs
        WHERE id = g.songid and gs.genre = g.genre),0);
            
        RETURN ret;

    END;
    $gs$ LANGUAGE plpgsql;


    CREATE OR REPLACE FUNCTION rs(myid BIGINT, fromtime time, totime time, inputstation varchar)
    RETURNS FLOAT AS $rs$
    DECLARE
        ret float;
        tempD text;
        avgrank float;
        avgrankplayed float;
    BEGIN

        SELECT s.decade into tempD FROM songs s WHERE s.id = myid;
        IF tempD IS NULL THEN ret = 0;
        RETURN ret;
        END IF;

        SELECT COALESCE(avg(rank), 0) into avgrank 
        FROM bilboard b WHERE b.songid = myid;
        IF avgrank = 0 THEN ret = 0;
        RETURN ret;
        END IF;

        DROP TABLE IF EXISTS bilboardrankfromsp;
        CREATE TABLE bilboardrankfromsp AS
            (
            SELECT b.songid as songid, s.decade as decade, avg(b.rank) as rank
            FROM songsplayed sp, bilboard b, songs s
            WHERE sp.songid = b.songid AND b.songid = s.id 
            GROUP BY b.songid, s.decade
            );

        DROP TABLE IF EXISTS bilboardranksamed;
        CREATE TABLE bilboardranksamed AS
            (
            SELECT b.decade AS decade, avg(b.rank) AS rank
            FROM bilboardrankfromsp b
            GROUP BY b.decade
            );

        SELECT COALESCE(avg(rank), 0) into avgrankplayed
        FROM bilboardranksamed b 
        WHERE b.decade = tempD;
        IF avgrankplayed = 0 THEN ret = 0;
        RETURN ret;
        END IF;

        IF avgrank - avgrankplayed = 0 THEN ret = 0;
        RETURN ret;
        END IF;

        ret = 1.0/abs(avgrank - avgrankplayed);
        RETURN ret;
    
    END;
    $rs$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION SS(myid BIGINT, fromtime time, totime time, inputstation varchar)
    RETURNS FLOAT AS $ss$

    DECLARE
        ret float;
        myenergy float;
        avgenergy float;
        myliveness float;
        avgliveness float;
        myacousticness float;
        avgacousticness float;
        temp float;
    BEGIN

        SELECT s.energy,s.liveness, s.acousticness INTO myenergy, myliveness,myacousticness FROM songs s WHERE myid = s.id ;
        SELECT avg(energy), avg(liveness), avg(acousticness) INTO avgenergy,avgliveness, avgacousticness FROM songs s, songsplayed sp WHERE s.id = sp.songid;

        IF myenergy IS NULL OR myliveness IS NULL OR myacousticness IS NULL OR avgenergy IS NULL OR avgliveness IS NULL OR avgacousticness IS NULL THEN
        ret = 0.0;
        RETURN ret;
        END IF;

        temp = abs(myenergy - avgenergy) + abs(myliveness - avgliveness) + abs(myacousticness - avgacousticness);

        IF temp = 0 THEN ret = 0;
        RETURN ret;
        END IF;

        ret = 1/temp;
        RETURN ret;

    END;
    $ss$ LANGUAGE plpgsql;




    DROP TABLE IF EXISTS songsnotplayed;
    CREATE TABLE songsnotplayed AS
    SELECT DISTINCT s.id as songid FROM songs s
    EXCEPT SELECT DISTINCT ss.songid FROM songsplayed ss;

   FOR myrow IN SELECT s.id as songid
                       , s.name as songname
		       , a.name as artistname
		       , w1 * gs(s.id,fromtime,totime,inputstation) + 
                w2 * rs(s.id,fromtime,totime,inputstation) +
               w3 * ss(s.id,fromtime,totime,inputstation) as songscore
         FROM songs s, artists a,songsnotplayed snp
         WHERE s.artistid = a.id AND snp.songid = s.id
         ORDER BY songscore DESC, songname ASC
	 LIMIT topk
   LOOP
       RETURN NEXT myrow ;
   END LOOP ;
   
   RETURN ;
END ;
$$ LANGUAGE plpgsql ;








select * from recommendation(time '08:00',time '10:00', 'mai', 20,0.05,1,1);
select * from recommendation(time '20:00',time '22:00', 'edge', 10,1,0,0);