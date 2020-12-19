#3proxy config generator
#!/bin/bash
# Copyright
# @LOUSO@
# li@louso.ru
# 2020

# Водим переменные
lnconf=/etc/3proxy.cfg
ipserv=185.230.140.75
# Формат admin:CL:123456
usradm=zorg:CL:09061310
# Файл со спископм пользователей. Формат логин:CL:пароль
userlist='user.list'

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
echo  Добавляем в конфиг Proxy адреса.
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

echo  Добавлено $count адресов с 30000 по $port порты.
echo  Перезагрузаю службу...

/bin/systemctl restart 3proxy.service
echo  Завершено.
echo  Successfully
