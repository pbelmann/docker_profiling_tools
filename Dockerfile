FROM linsalrob/cfk8bd:latest
MAINTAINER Stefan Janssen, stefan.m.janssen@gmail.com
ENV TOOLNAME focus

#needed if on Michaels cluster
#~ ENV http_proxy http://172.16.20.249:3128
#~ ENV https_proxy http://172.16.20.249:3128

#update underlying linux system
RUN apt-get update -y

#list of all dependencies that can be satisfied via the package management system of Ubuntu
ENV PACKAGES wget curl unzip seqtk make xz-utils ca-certificates
#install dependencies
RUN apt-get install -y --no-install-recommends ${PACKAGES}

#directory where additional software shall be installed
ENV PREFIX /biobox/
#create prefix directory and src subdirectory
RUN mkdir -p ${PREFIX}/src/ ${PREFIX}/bin/ ${PREFIX}/lib/ ${PREFIX}/share/ 
ENV PATH=${PREFIX}/bin:${PATH}

# Locations for biobox file validator
ENV VALIDATOR /bbx/validator/
ENV BASE_URL https://s3-us-west-1.amazonaws.com/bioboxes-tools/validate-biobox-file
ENV VERSION  0.x.y
RUN mkdir -p ${VALIDATOR}
# download the validate-biobox-file binary and extract it to the directory $VALIDATOR
RUN wget \
      --quiet \
      --output-document -\
      ${BASE_URL}/${VERSION}/validate-biobox-file.tar.xz \
    | tar xJf - \
      --directory ${VALIDATOR} \
      --no-same-owner \
      --strip-components=1
ENV PATH ${PATH}:${VALIDATOR}
#download yaml schema
RUN wget -q -O ${PREFIX}/share/schema.yaml https://raw.githubusercontent.com/pbelmann/rfc/feature/new-profiling-inteface/container/profiling/schema.yaml



#update program to Stefans standards
RUN ln -s /home/ ${PREFIX}/src/${TOOLNAME}
ADD focus2result.py.patch ${PREFIX}/src/${TOOLNAME}/
RUN patch ${PREFIX}/src/${TOOLNAME}/focus2result.py < ${PREFIX}/src/${TOOLNAME}/focus2result.py.patch
ADD focus_cami.py.patch ${PREFIX}/src/${TOOLNAME}/
RUN patch ${PREFIX}/src/${TOOLNAME}/focus_cami.py < ${PREFIX}/src/${TOOLNAME}/focus_cami.py.patch


ENV GITHUB https://raw.githubusercontent.com/CAMI-challenge/docker_profiling_tools/master/
#add my Perl scripts
ADD Utils.pm ${PREFIX}lib/Utils.pm
ADD YAML.pm ${PREFIX}lib/YAML.pm
ADD task_${TOOLNAME}.pl ${PREFIX}/bin/task.pl
RUN chmod a+x ${PREFIX}/bin/task.pl

ENV YAML "/bbx/mnt/input/biobox.yaml"
ENTRYPOINT ["task.pl"]
