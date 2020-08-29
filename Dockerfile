FROM ubuntu:18.04

RUN apt-get update -y && \
	apt-get -y install lib32stdc++6 python python-pip git wget

ENV SMVERSION=1.10

WORKDIR /usr/src
COPY . ./


RUN git clone https://github.com/splewis/sm-builder
WORKDIR /usr/src/sm-builder
RUN pip install --user -r requirements.txt
RUN python2 setup.py install --prefix=~/.local
WORKDIR /usr/src
RUN wget -O smpackage.tar.gz "http://sourcemod.net/latest.php?os=linux&version=${SMVERSION}"
RUN tar xfz smpackage.tar.gz
WORKDIR /usr/src/addons/sourcemod/scripting/
RUN chmod +x spcomp
WORKDIR /usr/src/addons/sourcemod/scripting/include
RUN wget https://raw.githubusercontent.com/KyleSanderson/SteamWorks/master/Pawn/includes/SteamWorks.inc
WORKDIR /usr/src
RUN cp -r ./dependencies/sm-json/addons/sourcemod/scripting/include/* ./addons/sourcemod/scripting/include

CMD ./docker-build.sh
