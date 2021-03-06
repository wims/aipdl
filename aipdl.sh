#!/bin/bash 

# defining variables here is not needed, but I like to keep them
# there for the sake of visibility
parameter=$1
airport_list=()
ICAO_code=""
airport_name=""
airport_city_name=""



# Downloads list of airports
function get_airport_list() {
    echo "*** DEBUG: get_airport_list()"

    local_airport_list="$version_number"
    local_airport_list+="_AD_LIST"
    counter=1
    return_string="-"

    echo "local_airport_list=$local_airport_list"

    # We only need to download if it doesnt already exist
    if [ ! -f $local_airport_list ]; then
        echo "local airport list not avail, downloading"
        wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" -O $local_airport_list $ad_list 
    fi

    while :
    do
        params="string(//html/body/div/div/div/div[2]/div[$counter]/h3/a/@href)"
        airport_object=$(xmllint --html --xpath "$params" $local_airport_list 2> /dev/null)

        counter=$(( $counter + 1 ))
        if [ "$airport_object" == "" ] 
        then 
            break
        else
            airport_list+=($airport_object)
        fi
    done
    echo "*** DEBUG: Finished get_airport_list()"
}

# Creates URL
function get_airport_url() {
    echo "*** DEBUG: get_airport_url()"

    get_airport_list
    echo "parameter = $parameter"
    for airport in ${airport_list[@]}; do
        if [[ "$airport" =~ "$parameter" ]]; then
            airport_url="${full_path}EN-AD-2.$1-no-NO.html#AD-2.$1"
            echo "Found airport url!"
            echo "airport_url = $airport_url"
            break
        fi
    done
    echo "*** DEBUG: Finished get_airport_url()"
}

function ICAO_to_text() {
    echo "*** DEBUG: ICAO_to_text()"

    get_airport_list
    index=1

    while : 
    do
        params="string(//div[@id='AD-0.6']/div[2]/div[$index]/h3/a/@href)"
        airport_icao=$(xmllint --html --xpath "$params" $local_airport_list)

        if [[ $ICAO_code == ${airport_icao:16:4} ]]; then
            params="string(//div[@id='AD-0.6']/div[2]/div[$index]/h3/a/span/span)"
            airport_city_name=$(xmllint --html --xpath "$params" $local_airport_list)

            params="string(//div[@id='AD-0.6']/div[2]/div[$index]/h3/a/span/span[4])"
            airport_name=$(xmllint --html --xpath "$params" $local_airport_list)

            echo "airport_city_name=$airport_city_name"
            echo "airport_name=$airport_name"
            return 1
        fi

        # params="string(//div[@id='AD-0.6']/div[2]/div[$index]/h3/a/span/span)"
        # city_name=$(xmllint --html --xpath "$params" $local_airport_list)

        # echo "city name = $city_name"

        index=$(( $index + 1 ))

        if [ "$airport_icao" == "" ] 
        then
            break
        fi
    done
}

# Extracts chart metadata and calls the download_chart function
function get_chart_meta_data() {
    echo "*** DEBUG: get_chart_meta_data()"

    remote_chart_list="EN-AD-2.$parameter-no-NO.html"
    index=1
    while :
    do
        div_id=$parameter"-AD-2.24"
        chart_name_params="string(//div[@id='$div_id']/table/tbody/tr[$index]/td[1]/p)"
        chart_name=$(xmllint --html --xpath "$chart_name_params" $remote_chart_list 2> /dev/null)

        chart_code_params="string(//div[@id='$div_id']/table/tbody/tr[$index]/td[2]/a)"
        chart_code=$(xmllint --html --xpath "$chart_code_params" $remote_chart_list 2> /dev/null)

        chart_filename_params="string(//div[@id='$div_id']/table/tbody/tr[$index]/td[2]/a/@href)"
        chart_filename=$(xmllint --html --xpath "$chart_filename_params" $remote_chart_list 2> /dev/null)

        index=$(( $index + 1 ))

        echo "chart_name = $chart_name"
        echo "chart_code = $chart_code"
        if [ "$chart_name" == "" ] 
        then
            break
        else
            download_chart $chart_name $chart_code $chart_filename
        fi
    done
}

# Downloads charts as PDF to local computer
function download_chart() {
    echo "*** DEBUG: download_chart()"

    if [ ! -d "$parameter" ]; then
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

    # Get substring from the 5th char to the end of ths string
    local_file_name=${chart_filename:5}
    local_chart_name=$(echo $chart_name | awk '{$1=$1;print}')
    local_chart_name="$local_chart_name.pdf"
    local_chart_name="${local_chart_name// /_}"
    local_chart_name="${local_chart_name////_}"

    cd $parameter
    if [ ! -d $subdir ]; then
        mkdir $subdir
    fi
    chart_url=$(echo $versioned_url"/"$date"-AIRAC"$local_file_name)
    cd $subdir
        #wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" -O $local_chart_name $chart_url 
    cd ../..

}

# Downloads chart metadata, and calls function to extract metadata
function download_airport_charts() {
    echo "*** DEBUG: download_airport_charts()"

    get_airport_url $1
    wget -U "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "$airport_url" 
    get_chart_meta_data
}

# This function gets the current version number of the AIS
function get_current_version() {
    echo "***DEBUG get_current_version()"
    base_url="https://ais.avinor.no/no/AIP/"

    version_number=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $base_url | grep -o 'Object moved to <a href="/no/AIP/View/[0-9]\{1,4\}' | awk -F / '{print $NF}')
    versioned_url=$(echo $base_url"view/"$version_number)
    versioned_endpoint=$(echo $versioned_url"/history-no-NO.html")

    if test -d "$version_number"; then
        echo "File exists!"
    else 
        echo "File does not exist!"
    fi
}

# This function gets meta files that contains the airport and chart info
function get_meta_files() {
    echo "***DEBUG: get_meta_files()"

    date=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $versioned_endpoint | awk '/date"><a href="/ {
    match($0, /date"><a href="/); print substr($0, RSTART + 15, 10);
    }') 
    full_path=$(echo $versioned_url"/"$date"-AIRAC/html/eAIP/")
    ad_list=$(echo $full_path"EN-AD-0.6-no-NO.html")
    answer=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" $ad_list | grep 'ENGM') 
    chart_list=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0" "$ad_list")
}

function usage() {
    echo "aipdl - A chart downloader"
    echo ""
    echo "Usage:"
    echo "  aipdl [options] <ICAO CODE>"
    echo ""
    echo "  ICAO CODE: The airports ICAO code"
}

# CHECK FOR COMMAND LINE OPTIONS
get_current_version
if [[ "$1" == "" ]]; then
    usage
    exit
elif [[ "$1" == --* ]]; then
    echo "Found option"
    if [ "$1" == "--find" ]; then
        ICAO_code=$2
        ICAO_to_text
        #get_airport_list
    else
        echo "Incorrect syntax"
    fi
else
    #get_current_version
    get_meta_files
    download_airport_charts $1
    #rm $remote_chart_list
fi

