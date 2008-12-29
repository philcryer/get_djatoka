#!/bin/bash

# simple script to download/setup djatoka image viewer in tomcat5.5 in Debian/Ubuntu

UNAME=`uname`
if [ "$UNAME" = "Linux" ] ; then
	if [ -f /etc/lsb-release ] ; then
		OSNAME="ubuntu" 
	elif [ -f /etc/debian_version ] ; then 
		OSNAME="debian" 
	else 
		echo " > ERROR: Unsupported Linux distribution" 
		echo " > this script will only work on Debian or Ubuntu"
		exit 1 
	fi
fi
echo " > Linux distro $OSNAME - supported..."

echo " > checking for tomcat..."
if [ ! -d "/var/lib/tomcat5.5" ]; then
	echo " > installing tomcat..."
	apt-get install tomcat5.5
fi

echo " > getting djatoka files..."
cd /tmp 
if [ ! -f "adore-djatoka-1.0.tar.gz" ]; then
	wget http://african.lanl.gov/aDORe/projects/djatoka/download/adore-djatoka-1.0.tar.gz
fi
if [ ! -f "adore-djatoka-viewer-1.0.tar.gz" ]; then
	wget http://african.lanl.gov/aDORe/projects/djatoka/download/adore-djatoka-viewer-1.0.tar.gz
fi
tar -zxf adore-djatoka-1.0.tar.gz ; tar -zxf adore-djatoka-viewer-1.0.tar.gz

echo " > fixing URL..."
cd adore-djatoka-1.0
export HOSTNAME=`hostname -f`; cat src/web/index.html | sed -e "s/localhost/${HOSTNAME}/g" | sed -e 's/8080/8180/g' > src/web/index.html.new
mv src/web/index.html.new src/web/index.html

echo " > building new war..."
ant clean
ant
cd -

echo " > installing djatoka to /var/lib..."
mv adore-djatoka-1.0 /var/lib/adore-djatoka

echo " > installing djatoka to tomcat..."
if [ -d "/var/lib/tomcat5.5/webapps/adore-djatoka" ]; then
	rm -rf /var/lib/tomcat5.5/webapps/adore-djatoka*
fi
cp /var/lib/adore-djatoka/dist/adore-djatoka.war /var/lib/tomcat5.5/webapps

echo " > adding djatoka variables to default/tomcat5.5"
echo "" >> /etc/default/tomcat5.5
echo "#### added for adore-djatoka support `date +%Y%m%d.%H%M%S` - start #### " >> /etc/default/tomcat5.5
echo "DJATOKA_HOME=\"/var/lib/adore-djatoka\"" >> /etc/default/tomcat5.5
echo "LAUNCHDIR=$DJATOKA_HOME/bin" >> /etc/default/tomcat5.5
tail -n46 /var/lib/adore-djatoka/bin/env.sh >> /etc/default/tomcat5.5
echo "#### added for adore-djatoka support - end #### " >> /etc/default/tomcat5.5
echo "" >> /etc/default/tomcat5.5

echo " > restarting tomcat..."
/etc/init.d/tomcat5.5 restart

#cat /root/bin/get_djatoka.sh
#exit 0

sleep 10

echo " > installing djatoka viewer..."
#cd /tmp/adore-djatoka-viewer-1.0
#cat viewer.html | sed -e "s/host\:port/$HOSTNAME\:8180/g" > viewer.html.new
#mv viewer.html.new viewer.html
#
#head -n18 index.html > index.html.foo; echo "<input type='text' id='input_addUrl' name='addUrl' size='50' value=\"http://memory.loc.gov/gmd/gmd433/g4330/g4330/np000066.jp2\">" >> index.html.foo; tail -n7 index.html >> index.html.foo; mv index.html.foo index.html
#mv index.html index_viewer.html 
cp -R /tmp/adore-djatoka-viewer-1.0/* /var/lib/tomcat5.5/webapps/adore-djatoka/

echo " > cleaning up..."
rm -rf adore-djatoka-1.0 adore-djatoka-viewer-1.0

echo " > done"
echo " > to see the base djatoka install hit:"
echo " > http://${HOSTNAME}:8180/adore-djatoka"
echo " > test URL=http://memory.loc.gov/gmd/gmd433/g4330/g4330/np000066.jp2"
#echo " > the optional viewer is available here:"
#echo " > http://$HOSTNAME:8180/adore-djatoka/index_viewer.html"

exit 0
