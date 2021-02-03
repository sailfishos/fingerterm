#ifndef VERSION_H
#define VERSION_H

#ifndef VERSION_STRING
// It's expected that VERSION_STRING will be defined by the build engine
#define VERSION_STRING "0.0.0"
#endif

const QString PROGRAM_VERSION=QLatin1String(VERSION_STRING);
#endif

