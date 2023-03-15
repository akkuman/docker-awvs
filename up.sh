#!/bin/bash


version=v_200807155
db_port=35432
linux_user=acunetix
product_name=acunetix
engine_only=0

# 启动数据库
if [ $engine_only != 1 ]; then
    echo "attempting to stop previous database"
    ~/.$product_name/$version/database/bin/pg_ctl -D ~/.$product_name/db -w stop

    rm -rf ~/.$product_name/db/postmaster.pid

    echo "attempting to start the db"
    setsid ~/.$product_name/$version/database/bin/pg_ctl -D ~/.$product_name/db -o "--port=$db_port" -w start
fi

# 修改账号密码和token
base_folder="/home/$linux_user/.$product_name"

get_settings_from_ini()
{
    db_user=$(awk -F "=" '/databases.connections.master.connection.user/ {print $2}' $base_folder/wvs.ini)
    if [ -z "$db_user" ]; then
        echo "Acunetix installation found at $base_folder, but has invalid wvs.ini file. Aborting installation."
        echo
        exit -1
    fi

    db_host=$(awk -F "=" '/databases.connections.master.connection.host/ {print $2}' $base_folder/wvs.ini)
    if [ -z "$db_host" ]; then
        echo "Acunetix installation found at $base_folder, but has invalid wvs.ini file. Aborting installation."
        echo
        exit -1
    fi

    db_port=$(awk -F "=" '/databases.connections.master.connection.port/ {print $2}' $base_folder/wvs.ini)
    if [ -z "$db_port" ]; then
        echo "Acunetix installation found at $base_folder, but has invalid wvs.ini file. Aborting installation."
        echo
        exit -1
    fi

    db_name=$(awk -F "=" '/databases.connections.master.connection.db/ {print $2}' $base_folder/wvs.ini)
    if [ -z "$db_name" ]; then
        echo "Acunetix installation found at $base_folder, but has invalid wvs.ini file. Aborting installation."
        echo
        exit -1
    fi

    db_password=$(awk -F "=" '/databases.connections.master.connection.password/ {print $2}' $base_folder/wvs.ini)
    if [ -z "$db_password" ]; then
        echo "Acunetix installation found at $base_folder, but has invalid wvs.ini file. Aborting installation."
        echo
        exit -1
    fi

    gr="(?<=wvs\.app_dir\=~\/\.$product_name\/v_)[0-9]+(?=\/scanner)"
    version_numeric=$(cat $base_folder/wvs.ini | grep -o -P $gr)
    version="v_$version_numeric"
}

get_settings_from_ini

db_pgdir="$base_folder/$version/database"

run_db_sql(){

    PGPASSWORD=$db_password $db_pgdir/bin/psql -q -d $db_name -t -c "$1" -b -h $db_host -p $db_port -U $db_user -v ON_ERROR_STOP=1
    if [ "$?" -ne 0 ]; then
        echo "Error running SQL command. Exiting."
        exit -1
    fi
}

#get the previous master user
qr=$(run_db_sql "SELECT email FROM users WHERE user_id='986ad8c0a5b3df4d7028d5f3c06e936c'")
master_user=$(echo "$qr" | awk '{$1=$1};1')

echo "old master user: $master_user"

get_password_score()
{
    score=0
    if [[ $1 =~ [A-Z] ]]; then
            #echo "CAPS found"
            score=$(( $score+1 ))
    fi

    if [[ $1 =~ [a-z] ]]; then
            #echo "normal found"
            score=$(( $score+1 ))
    fi

    if [[ $1 =~ [0-9] ]]; then
            #echo "number found"
            score=$(( $score+1 ))
    fi

    if [[ $1 =~ [!-/:-@\[-\`{-~] ]]; then
            #echo "special found"
            score=$(( $score+1 ))
    fi

    return $score
}


regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+"
if [ $AWVS_USERNAME ];then
    master_user=$AWVS_USERNAME
	echo $AWVS_USERNAME | egrep --quiet $regex
    if [ "$?" -ne 0 ] ; then
        echo "Bad email format."
        exit 1
    fi
fi
if [ $AWVS_PASSWORD ];then
	master_password=$AWVS_PASSWORD
    if [ ${#master_password} -lt 8 ]; then
        echo "Password has to be of minimum 8 characters, containing at least 3 of the following:"
        echo "1 number, 1 small letter, 1 capital letter and 1 special character e.g. !@#$% etc."
        exit 1
    fi
    get_password_score $master_password
    if [ $? -lt 3 ]; then
        echo "Password has to be of minimum 8 characters, containing at least 3 of the following:"
        echo "1 number, 1 small letter, 1 capital letter and 1 special character e.g. !@#$% etc."
        exit 1
    fi
fi
if [ $AWVS_APIKEY ]; then
    master_apikey=$AWVS_APIKEY
    if ! [[ $AWVS_APIKEY =~ ^[a-f0-9]{32}$ ]]; then
        echo "APIKEY must be an MD5 string."
        exit 1
    fi
fi

# 执行变更
if [ $AWVS_USERNAME ];then
    run_db_sql "UPDATE users SET email='$master_user' WHERE user_id='986ad8c0a5b3df4d7028d5f3c06e936c'"
    echo "User: $master_user"
fi
if [ $AWVS_PASSWORD ];then
    run_db_sql "UPDATE users SET password=encode(digest('$master_password', 'sha256'), 'hex'), pwd_expires = null WHERE user_id='986ad8c0a5b3df4d7028d5f3c06e936c'"
    echo "Pass: $master_password"
fi
if [ $AWVS_APIKEY ]; then
    run_db_sql "UPDATE users SET api_key='$master_apikey' WHERE user_id='986ad8c0a5b3df4d7028d5f3c06e936c'"
    echo "Key: 1986ad8c0a5b3df4d7028d5f3c06e936c$master_apikey"
fi

run_db_sql "DELETE FROM ui_sessions"


# 启动awvs
echo "attempting to start the backend"
cd ~/.$product_name/$version/backend/
~/.$product_name/$version/backend/opsrv --conf ~/.$product_name/wvs.ini
