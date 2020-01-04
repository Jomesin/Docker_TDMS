FROM scratch
# 该镜像为CentOS基础镜像

MAINTAINER "JISO"

ADD centos-7-x86_64-docker.tar.xz /

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.name="CentOS-7_Basic" \
    org.label-schema.license="GPLv2" \
    org.label-schema.build-date="20191226"

# 安装make指令准备进行python的解压编译
COPY make-3.82-24.el7.x86_64.rpm /root/appbackage/
RUN yum -y install /root/appbackage/make-3.82-24.el7.x86_64.rpm

# 安装python3.6.5
ADD Python-3.6.5.tgz /root/appbackage
# 编译然后软连接到/usr/bin/python3目录下
RUN yum -y install gcc-c++ zlib* unzip zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel && \
 /root/appbackage/Python-3.6.5/configure --prefix=/usr/local/python3 --with-ssl && \
  make && make install && \
   ln -s /usr/local/python3/bin/python3 /usr/bin/python3 && \
    ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3

# 安装Oracle即时客户端
COPY instantclient-basic-linux.x64-12.2.0.1.0.zip /root/
# 安装python所使用的的虚拟环境
RUN unzip -d /root /root/instantclient-basic-linux.x64-12.2.0.1.0.zip && \ 
rm /root/instantclient-basic-linux.x64-12.2.0.1.0.zip
# 解决纯净系统内的编码问题,因为此会导致python安包错误
ENV LANG=en_US.utf8
ENV ORACLE_HOME=/root/instantclient_12_2/
ENV DYLD_LIBRARY_PATH=$ORACLE_HOME
ENV LD_LIBRARY_PATH=$ORACLE_HOME
ENV NLS_LANG=AMERICAN_AMERICA.UTF8
ENV TNS_ADMIN=$ORACLE_HOME
ENV PATH=$PATH:$ORACLE_HOME
#COPY .bash_profile /root/
#RUN source /root/.bash_profile

# 编译nginx源码
ADD nginx-1.12.2.tar.gz /root/appbackage
WORKDIR /root/appbackage/nginx-1.12.2
RUN ./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log && make && make install && rm -rf /root/appbackage/*

# 打包源代码
COPY tdms-python/tdms /root/tdms/
WORKDIR /root/tdms
RUN pip3 install -i https://pypi.python.org/simple/ --upgrade pip && pip3 install -i https://pypi.python.org/simple/ -r requirements.txt
COPY process_collector.py /usr/local/python3/lib/python3.6/site-packages/prometheus_client/

# 暴露443和80端口
EXPOSE 443 80

# 复制nginx配置文件和uwsgi配置文件
ADD conf.d /etc/nginx
COPY nginx.conf /etc/nginx
COPY uwsgi.ini /root/uwsgi

# 关闭守护进程
RUN echo "daemon off;">>/etc/nginx/nginx.conf
ADD run.sh /root
RUN chmod 775 /root/run.sh
CMD ["/root/run.sh"]
