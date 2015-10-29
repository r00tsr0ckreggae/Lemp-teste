FROM centos:6.7
MAINTAINER dusilva@fcl.com.br

# Set timezone
RUN rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/UTC /etc/localtime

# Additional Repos
RUN yum -y install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
    http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    yum-utils wget unzip && \
    yum-config-manager --enable remi,remi-php56,remi-php56-debuginfo


## Install php nginx mysql supervisor
RUN apt-get update && \
    apt-get install -y php5-fpm php5-cli php5-gd php5-mcrypt php5-mysql php5-curl \
                       nginx \
		       supervisor && \
    echo "mysql-server mysql-server/root_password password" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    rm -rf /var/lib/apt/lists/*
## Clean up, reduces container size
RUN rm -rf /var/cache/yum/* && yum clean all

## Configuration
# php-fpm
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php5/fpm/pool.d/www.conf && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php5\/cgi.log/' /etc/php5/fpm/php.ini && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php5\/cli.log/' /etc/php5/cli/php.ini && \
    mkdir /var/log/php5/ && \
    touch /var/log/php5/cli.log /var/log/php5/cgi.log && \
    chown www-data:www-data /var/log/php5/cgi.log /var/log/php5/cli.log

# nginx
RUN unlink /etc/nginx/sites-enabled/default
ADD nginx/default /etc/nginx/sites-enabled/default
RUN mkdir /var/www/
ADD nginx/index.php /var/www/
RUN chown -R www-data:www-data /var/www/

# mysql
RUN sed -i 's/^key_buffer\s*=/key_buffer_size =/' /etc/mysql/my.cnf
RUN chown -R mysql:mysql /var/lib/mysql

# supervisor
ADD supervisor/php5-fpm.conf /etc/supervisor/conf.d/php5-fpm.conf
ADD supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf
ADD supervisor/mysql.conf /etc/supervisor/conf.d/mysql.conf

WORKDIR /var/www/

VOLUME /var/www/
EXPOSE 80

CMD ["/usr/bin/supervisord", "--nodaemon", "-c", "/etc/supervisor/supervisord.conf"]