#!/bin/sh

# ./create_domain.sh domain=mail.ru extradomain="www.mail.ru pop3.mail.ru" backend=apache1-back.local backend_port=8080


nginx_path="/etc/nginx"
nginx_templates=$nginx_path"/templates"
nginx_sites_available=$nginx_path"/sites_available"
nginx_sites_enabled=$nginx_path"/sites_enabled"


args=("$@")

x=0
cmd=0

for i in $@;
do

    arg=$(echo ${args[$x]} |awk '{split($0,a,"=");print a[1]}')
    val=$(echo ${args[$x]} |awk '{split($0,a,"=");print a[2]}') #'
    
    if [ "$arg" == "domain" ];
    then
	domain=$val
    fi
    if [ "$arg" == "extradomain" ];
    then
	moredomains=$val
    fi
    if [ "$arg" == "backend" ];
    then
	backend=$val
    fi
    if [ "$arg" == "backend_port" ];
    then
	backend_port=$val
    fi
    x=`expr $x + 1`
    cmd=1
done



check_str_value() {
    arg1=$*
    rc=$(echo $arg1 | grep -vE '[^a-zA-Z0-9\. -]')
    if [ $? -ne 0 ];
    then
        echo "Wrong!"
        echo "English letters only. To issue for an Internationalized Domain Name, use Punycode."
        exit 1
    fi
};

check_empty() {
    str=$1
    if [ -z $str ];
    then
	echo "Wrong"
	echo "Value can't be empty, brat"
	exit 1
    fi
}

check_int_value() {
    arg1=$1
    rc=$(echo $arg1 | grep -vE '[^0-9]')
    if [ $? -ne 0 ];
    then
        echo "Wrong!"
        echo "Digits only, ebta"
        exit 1
    fi
};


if [ -z "$domain" -a $cmd -ne 1 ];
then
    echo -n "Enter domain name: "
    read domain
fi

echo -n "domain - "
check_str_value $domain
check_empty $domain
echo "ok"

if [ -z "$moredomains" -a $cmd -ne 1 ];
then
    echo "Is there any additional domains?"
    echo "Enter additional domains separate by space."
    echo -n "If not, just press enter: "
    read moredomains
fi

echo -n "more domains - "
check_str_value $moredomains
echo "ok"

if [ -z "$backend" -a $cmd -ne 1 ];
then
    echo -n "Enter backend server name: "
    read backend
fi

echo -n "backend - "
check_str_value $backend
check_empty $backend
echo "ok"

if [ -z "$backend_port" -a $cmd -ne 1 ];
then
    echo -n "Enter backend server port (80 by default): "
    read backend_port
fi
echo -n "backend port - "
check_int_value $backend_port
echo "ok"


if [ ! -a "$moredomains" ];
then
    domains=$domain" "$moredomains
else
    domains=$domain
fi

if [ -z "$backend_port" ];
then
    backend_port=80
fi



create_http() {
    rules="s/{{domain_names}}/$domains/g;s/{{host_name}}/$backend/g;s/{{host_port}}/$backend_port/g;s/{{domain_name}}/$domain/g"
    cat $nginx_templates/host.conf|sed -e "$rules" >$nginx_sites_available/$domain.conf
    ln -s $nginx_sites_available/$domain.conf $nginx_sites_enabled/$domain.conf
}

create_https() {
    rules="s/{{domain_names}}/$domains/g;s/{{host_name}}/$backend/g;s/{{host_port}}/$backend_port/g;s/{{domain_name}}/$domain/g"
    cat $nginx_templates/host_ssl.conf|sed -e "$rules" >$nginx_sites_available/$domain""_ssl.conf
    ln -s $nginx_sites_available/$domain""_ssl.conf $nginx_sites_enabled/$domain""_ssl.conf
}

create_ssl() {
    certbot certonly --agree-tos --email admin@shopband.ru --webroot -w /var/www/lets -d $domain
}

nginx_restart() {
    service nginx restart
}


create_http
nginx_restart
sleep 1
create_ssl
create_https
nginx_restart

