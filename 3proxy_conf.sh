#3proxy config generator
#!/bin/bash
# Copyright
# @LOUSO@
# li@louso.ru
# 2020

# Водим переменные
lnconf=/etc/3proxy.cfg #путь к конфигу 3Proxy
ipserv=185.230.140.75 #Адрес сервера внешний
MAXCOUNT=255 #сколько адресов IPv6 нам нужно использовать
network=2a07:14c0:1:6720 # наша ipv6 сеть /64
array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f ) # Символы для генерации !не трогаем!.
countip=1 # Стетчик для адресов !не трогаем!
# Формат admin:CL:123456
usradm=zorg:CL:09061310
# Файл со спископм пользователей. Формат логин:CL:пароль
userlist='user.list'
# Обновить список адресов в файле ip.list
# Проверка наличия файлов
[ -f "ip.list" ] && echo "Файл ip.list существует" || echo "Файл ip.list не существует. Создаём..." touch ip.list
[ -f "user.list" ] && echo "Файл user.list существует" || echo "Файл user.list не существует. Создаём..." touch user.list
#regenip=1 # 0-не генерировать. 1- перегенераровать.
#if $regenip=1
#then
echo Генерируем адреса в файл ...
rm ip.list
touch ip.list
rnd_ip_block ()
{
    a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    echo $network:$a:$b:$c:$d >> ip3.list
}
while [ "$countip" -le $MAXCOUNT ]        # Генерация 20 ($MAXCOUNT) случайных чисел.
do
        rnd_ip_block
        let "countip += 1"                # Нарастить счетчик.
        done

#####################
echo Обновляем конфиг....
rm $lnconf
touch $lnconf
echo nscache 65536 >> $lnconf
echo nscache6 65535 >> $lnconf
echo daemon >> $lnconf
echo timeouts 1 5 30 60 180 1800 15 60 >> $lnconf
echo  >> $lnconf
echo log /var/log/3proxy/3proxy-%y%m%d.log >> $lnconf
echo rotate 30 >> $lnconf
echo  >> $lnconf
echo external $ipserv >> $lnconf
echo internal $ipserv >> $lnconf
echo  >> $lnconf
echo auth strong >> $lnconf
echo users zorg:CL:09061310 >> $lnconf
#echo allow $usradm >> $lnconf
echo allow $usradm | rev | cut -d: -f3-| rev >> $lnconf
echo 'allow * * * *' >> $lnconf
echo proxy -4 -n -p3128 -a -i$ipserv -e$ipserv >> $lnconf
echo  >> $lnconf
echo auth strong >> $lnconf

echo Завершено.
echo Прописываем пользователей...
while read usr; do
    echo users $usr >> $lnconf
    #echo allow $usr >> $lnconf
    echo allow $usr | rev | cut -d: -f3-| rev >> $lnconf
done < $userlist

echo 'allow * * * * *' >> $lnconf
#39
echo  >> $lnconf
echo  Прользователи прописаны.
echo  Добавляем в конфиг IPv6 адреса из дайла ip.list.
port=30000
count=1
for i in `cat ip.list`; do
    echo "proxy -6 -s0 -n -a -p$port -i$ipserv -e$i" >> $lnconf
((port+=1))
    ((count+=1))
    if [ $count -eq 10001 ]; then
        exit
    fi
done

echo  Добавлены прокси с 30000 по $port порты.
echo  Перезагружаю службу...

/bin/systemctl restart 3proxy.service
echo  Перезапуск завершен.
# Проверяем как запустилась служба и отсылаем отчет в телеграм.
echo  Проверяем корректную работу служб....
function checkIt()
{
 ps auxw | grep -P '\b'$1'(?!-)\b' >/dev/null
 if [ $? != 0 ]
 then
   echo $1 "failed";
# Отсылаем в  Телеграм сообешие об ошибке работы.
#curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"-1001221927062","text":"Сбой в работе 185.230.140.75!"}' "https://api.telegram.org/bot253407620:AAHaG-kQBDfLp5Cif7Fs2te5NO$
 else
   echo $1 "active";
# Отсылаем в  Телеграм сообщение об обновлении адресов.
#curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"-1001221927062","text":"Proxy 185.230.140.75. Адреса обновлены удачно."}' "https://api.telegram.org/bot253407620:AAHaG-kQB$
 fi;
}

checkIt "3proxy"
checkIt "rclocal"
checkIt "sshd"
