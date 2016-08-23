Create a config file named "config.yml" in the root of project

Then, insert your configs, see a sample:

~~~~
projects:
  cartolaevolution: &cinezap
    file_path: "/Users/cajuina/Desktop/cinezap/project.xml"
    android_package: "br.com.cinezap"
    migration_datetime: "2015-10-21'T'14:05:20"
  cartolaevolution: &stalaura
    file_path: "/Users/cajuina/Desktop/stalaura/project.xml"
    android_package: "br.com.stalaura"
    migration_datetime: "2015-10-23'T'14:20:30"
  cartolaevolution: &cartolaevolution
    file_path: "/Users/cajuina/Desktop/cartolaevolution/project.xml"
    android_package: "br.com.cartolaevolution"
    migration_datetime: "2016-06-21'T'10:01:01"

config:
  <<: *cartolaevolution
~~~~