import requests
from bs4 import BeautifulSoup
from urllib.request import urlretrieve

from urllib.error import URLError          #异常处理模块，捕获错误
from urllib.request import ProxyHandler, build_opener   #代理IP模块

if __name__ == "__main__":
    url = 'https://www.cs.rpi.edu/~sibel/dbs_notes/fall2021_lecture_notes/'
    proxy_handler = ProxyHandler({
        'http': '127.0.0.0:4973'
     
    })
    opener = build_opener(proxy_handler)   #通过proxy_handler来构建opener
    strhtml = requests.get(url)
    soup = BeautifulSoup(strhtml.text, 'html')
    data = soup.select('tr > td> a')
    for i in range(len(data)):
        if i == 0:
            continue
        href = data[i]['href']
        #请求网站
        totalhref = "https://www.cs.rpi.edu/~sibel/dbs_notes/fall2021_lecture_notes/"+href 
        r = requests.get(totalhref).content
        with open(href, "wb") as f:
            f.write(r)