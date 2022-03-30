#!/bin/bash 

base_url="https://ais.avinor.no/no/AIP/"
version="view/"


version_number=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $base_url | grep -o 'Object moved to <a href="/no/AIP/View/[0-9]\{1,4\}' | awk -F / '{print $NF}')

versioned_url=$(echo $base_url$version$version_number)

versioned_endpoint=$(echo $versioned_url"/history-no-NO.html")

echo $versioned_endpoint

date=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $versioned_endpoint | awk '/date"><a href="/ {
    match($0, /date"><a href="/); print substr($0, RSTART + 15, 10);
}') 

echo $date

full_path=$(echo $versioned_url"/"$date"-AIRAC/html/eAIP/")

echo $full_path


ad_list=$(echo $full_path"EN-AD-0.6-no-NO.html")

answer=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $ad_list | grep 'ENGM') 

echo $answer

chart_list=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-2.ENAT-no-NO.html#ENAT-AD-2.24)

echo $chart_list

# https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-0.6-no-NO.html


#curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" 

#wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" ""