#!/bin/bash 
parameter=$1
base_url="https://ais.avinor.no/no/AIP/"
version="view/"

airport_list=()
chart_name=""


function get_airport_list() {
    echo "*** DEBUG: get_airport_list()"

    wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-0.6-no-NO.html"

    counter=1
    return_string="-"

    while :
    do
        declare -a "start_string=(xmllint --html --xpath \"string(//html/body/div/div/div/div[2]/div[$counter]/h3/a/@href)\" EN-AD-0.6-no-NO.html)"
        #echo "start string = ${start_string[@]}"
        return_string=$(${start_string[@]})
        #echo "return string = $return_string"
        counter=$(( $counter + 1 ))
        if [ "$return_string" == "" ] 
        then 
            break
        else
            airport_list+=($return_string)
        fi
    done
}

function get_airport_url() {
    echo "*** DEBUG: get_airport_url()"
    get_airport_list
    airport_url=""
    for airport in ${airport_list[@]}; do
        if [[ "$airport" =~ "$1" ]] 
        then
            #airport_url="https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-2.$1-no-NO.html#AD-2.$1"
            airport_url="${full_path}EN-AD-2.$1-no-NO.html#AD-2.$1"
            return 0
        fi
    done
}

function get_chart_name() {
    echo "*** DEBUG: get_chart_name()"
    chart_name=$(xmllint --html --xpath "$chart_name_params" EN-AD-2.ENGM-no-NO.html 2> /dev/null)
    #echo "return_string=$return_string"
}

function get_chart_code() {
    echo "*** DEBUG: get_chart_code()"
    chart_code=""
    chart_code=$(xmllint --html --xpath "$chart_code_params" EN-AD-2.ENGM-no-NO.html 2> /dev/null)
}

function get_chart_filename() {
    echo "*** DEBUG: get_chart_filename()"
    chart_filename=""
    chart_filename=$(xmllint --html --xpath "$chart_filename_params" EN-AD-2.ENGM-no-NO.html 2> /dev/null)
}

function get_meta_data() {
    echo "*** DEBUG: get_meta_data()"
    

}

function get_ground_charts() {
    echo "*** DEBUG: get_ground_charts()"
    index=1
    while :
    do
        chart_name_params="string(//html/body/div[2]/div[24]/table/tbody/tr[$index]/td[1]/p)"
        get_chart_name $chart_name_params

        chart_code_params="string(//html/body/div[2]/div[24]/table/tbody/tr[$index]/td[2]/a)"
        get_chart_code $chart_code_params

        chart_filename_params="string(//html/body/div[2]/div[24]/table/tbody/tr[$index]/td[2]/a/@href)"
        get_chart_filename $chart_filename_params
        

        index=$(( $index + 1 ))
        if [ "$chart_name" == "" ] 
        then 
            break
        else
            echo "chart name = $chart_name"
            echo "chart code = $chart_code"
            echo "chart fn   = $chart_filename"
            #airport_list+=($return_string)
        fi
    done
}

function download_airport_charts() {
    echo "*** DEBUG: download_airport_charts()"
    get_airport_url $1
    echo "Airport url = $airport_url"
    wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "$airport_url"

    get_ground_charts 
}

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

echo $ad_list

answer=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $ad_list | grep 'ENGM') 

#echo $answer

chart_list=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-2.ENAT-no-NO.html#ENAT-AD-2.24)

#echo $chart_list

#wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-0.6-no-NO.html"

# CHECK FOR COMMAND LINE OPTIONS

if [[ "$1" == --* ]]
then
    echo "Found option"
    if [ "$1" == "--find" ]
    then
        get_airport_list
    else
        echo "Incorrect syntax"
    fi
else
    download_airport_charts $1
fi



# https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-0.6-no-NO.html


#curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" 

#wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" ""