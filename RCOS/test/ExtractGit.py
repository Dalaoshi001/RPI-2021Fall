import requests
from bs4 import BeautifulSoup

if __name__ == "__main__":
    url = 'https://science.rpi.edu/computer-science/faculty'
    strhtml = requests.get(url)
    soup = BeautifulSoup(strhtml.text, 'lxml')
    data = soup.select('h3 > a')
    for d in data:
        print('https://science.rpi.edu' + d['href'])
