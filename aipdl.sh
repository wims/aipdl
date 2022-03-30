#!/bin/bash 

base_url="https://ais.avinor.no/no/AIP/"
version="view/"


version_number=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $base_url | grep -o 'Object moved to <a href="/no/AIP/View/[0-9]\{1,4\}' | awk -F / '{print $NF}')

versioned_url=$(echo $base_url$version$version_number"/history-no-NO.html")

echo $versioned_url

date=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $versioned_url | awk '/date"><a href="/ {
    match($0, /date"><a href="/); print substr($0, RSTART + 15, 10);
}') 

echo $date


#curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" 

#wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" ""