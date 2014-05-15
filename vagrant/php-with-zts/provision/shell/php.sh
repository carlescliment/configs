tmp_folder="/home/vagrant/tmp"
packages_folder="/vagrant/provision/packages"

# Extract file
mkdir $tmp_folder
cp $packages_folder/php-5.5.12.tar.bz2 $tmp_folder
cd $tmp_folder
bunzip2 php-5.5.12.tar.bz2
tar xvf php-5.5.12.tar
cd php-5.5.12

# Configure PHP
./configure --enable-debug --enable-maintainer-zts --enable-pthreads
make install


# Install pthreads
cd $tmp_folder
curl -OL http://ftpmirror.gnu.org/autoconf/autoconf-latest.tar.gz
tar xzf autoconf-latest.tar.gz
cd autoconf-*
./configure --prefix=/usr/local
make
make install
pecl install pthreads

cp $packages_folder/php.ini /usr/local/lib/
