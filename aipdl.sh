#!/bin/bash 
parameter=$1
base_url="https://ais.avinor.no/no/AIP/"
version="view/"

airport_list=()
chart_name=""


function get_airport_list() {
    echo "*** DEBUG: get_airport_list()"

    local_airport_list="$version_number"
    local_airport_list+="_AD_LIST"
    echo "local_airport_list = $local_airport_list"

    wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" -O $local_airport_list $ad_list 

    counter=1
    return_string="-"

    while :
    do
        declare -a "start_string=(xmllint --html --xpath \"string(//html/body/div/div/div/div[2]/div[$counter]/h3/a/@href)\" $local_airport_list)"
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
        if [[ "$airport" =~ "$parameter" ]] 
        then
            airport_url="${full_path}EN-AD-2.$1-no-NO.html#AD-2.$1"
            return 0
        fi
    done
}


function get_chart_meta_data() {
    echo "*** DEBUG: get_chart_meta_data()"
    index=1
    while :
    do
        chart_name_params="string(//html/body/div[2]/div/div[24]/table/tbody/tr[$index]/td[1]/p)"
        chart_name=$(xmllint --html --xpath "$chart_name_params" $remote_chart_list 2> /dev/null)
        #get_chart_name $chart_name_params

        chart_code_params="string(//html/body/div[2]/div/div[24]/table/tbody/tr[$index]/td[2]/a)"
        chart_code=$(xmllint --html --xpath "$chart_code_params" $remote_chart_list 2> /dev/null)
        #get_chart_code $chart_code_params

        chart_filename_params="string(//html/body/div[2]/div/div[24]/table/tbody/tr[$index]/td[2]/a/@href)"
        chart_filename=$(xmllint --html --xpath "$chart_filename_params" $remote_chart_list 2> /dev/null)
        #get_chart_filename $chart_filename_params

        index=$(( $index + 1 ))

        if [ "$chart_name" == "" ] 
        then
            break
        else
            #echo "Airport found!"
            #echo "chart name = $chart_name"
            #echo "chart code = $chart_code"
            #echo "chart fn   = $chart_filename"
            download_chart $chart_name $chart_code $chart_filename
            #airport_list+=($return_string)
        fi
    done
}

function download_chart() {
    echo "*** DEBUG: download_chart()"
    if [ ! -d "$parameter" ]; then
        #echo "Directory $parameter does not exist, creating"
        mkdir $parameter
    fi
    if [[ ${chart_code:13:1} == "2" ]]; then
        subdir="Ground"
    elif [[ ${chart_code:13:1} == "3" ]]; then
        subdir="Obstacle"
    elif [[ ${chart_code:13:1} == "4" ]]; then
        subdir="SIDSTAR"
    elif [[ ${chart_code:13:1} == "5" ]]; then
        subdir="Approach"
    elif [[ ${chart_code:13:1} == "6" ]]; then
        subdir="Visual"
    else 
        subdir="Area"
    fi

    #echo "Subdir = $subdir"

    local_file_name=${chart_filename:5}
    #echo "local_file_name = $local_file_name"
    local_chart_name=$(echo $chart_name | awk '{$1=$1;print}')
    local_chart_name="$local_chart_name.pdf"
    local_chart_name="${local_chart_name// /_}"
    local_chart_name="${local_chart_name////_}"
    #echo "local_chart_name = $local_chart_name"

    cd $parameter
    if [ ! -d $subdir ]; then
        mkdir $subdir
    fi

    chart_url=$(echo $versioned_url"/"$date"-AIRAC"$local_file_name)

    #echo "chart url = $chart_url"

    cd $subdir
        #wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" -O $local_chart_name $chart_url 
    cd ../..

}

function download_airport_charts() {
    echo "*** DEBUG: download_airport_charts()"
    get_airport_url $1
    #echo "Airport url = $airport_url"
    wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "$airport_url" 

    get_chart_meta_data
}


function get_current_version() {
    echo "***DEBUG get_current_version()"
    version_number=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $base_url | grep -o 'Object moved to <a href="/no/AIP/View/[0-9]\{1,4\}' | awk -F / '{print $NF}')

    versioned_url=$(echo $base_url$version$version_number)

    versioned_endpoint=$(echo $versioned_url"/history-no-NO.html")

    # echo "version_number = $version_number"


    if test -d "$version_number"; then
        echo "File exists!"
    else 
        echo "File does not exist!"
    fi
}

function get_meta_files() {
    echo "***DEBUG: get_meta_files()"
    date=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $versioned_endpoint | awk '/date"><a href="/ {
    match($0, /date"><a href="/); print substr($0, RSTART + 15, 10);
    }') 

    #echo $date

    full_path=$(echo $versioned_url"/"$date"-AIRAC/html/eAIP/")

    #echo $full_path


    ad_list=$(echo $full_path"EN-AD-0.6-no-NO.html")

    #echo "ad_list = $ad_list"

    answer=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $ad_list | grep 'ENGM') 

    #echo $answer

    chart_list=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "$ad_list")

    #echo "CHART LIST = $chart_list"

}

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
    remote_chart_list="EN-AD-2.$parameter-no-NO.html"
    get_current_version
    get_meta_files
    download_airport_charts $1
    rm $remote_chart_list
fi



# https://ais.avinor.no/no/AIP/view/112/2022-03-24-AIRAC/html/eAIP/EN-AD-0.6-no-NO.html


#curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" 

#wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" ""