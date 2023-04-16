


def PowerSetBinary(items):
    combination=[]
    N = len(items)
    for i in range(2**N):
        combo = []
        for j in range(N):
            if(i>>j)%2:
                combo.append(items[j])
        #print(combo)
        combination.append(combo)
    return combination

def check(a,b):
    lista = list(a)
    for i in lista:
        if not (i in b):
            return False
    return True

def checklist(a,b):
    count=0
    for i in b:
        for j in a:
            if(i == j):
                count = count+1
    if(count == len(b) and len(a)> len(b)):
        return False
    else:
        return True

if(__name__ == "__main__"):
    #PowerSetBinary([1,2,3,4,5])
    words=""
    total = ""
    total = input("total: ")
    fromwords=[]
    towords=[]
    proanswer=[]
    while(words!= "quit"):
        words = input("from: ")
        if(words == "quit"):
            break
        fromwords.append(words)
        words = input("to: ")
        if(words == "quit"):
            break
        towords.append(words)
    
    totals=[] 
    totals = total
    allpossible = PowerSetBinary(totals)
    for i  in allpossible:
        a=set()
        for k in i:
            a.add(k)
        alen = len(a)
        last = 0
        while(alen>last):
            last = alen
            for j in range(0,len(towords)):
                if(check(fromwords[j],a)):
                    for l in towords[j]:
                        a.add(l)
                alen = len(a)
            
        if(alen == len(totals)):
            proanswer.append(i)

    #print(proanswer)
    finalanswer=[]
    for i in proanswer:
        flag  = True
        for j in proanswer:
            if (checklist(i,j) == False):
                flag = False
                break               
        if(flag == True):
            finalanswer.append(i)
    
    print(finalanswer)

