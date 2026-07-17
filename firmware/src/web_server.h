#ifndef WEB_SERVER_H
#define WEB_SERVER_H

#include <Arduino.h>
#include <WebServer.h>

class BeehiveWebServer {
 public:
  BeehiveWebServer();
  void begin();
  void handleClient();

 private:
  WebServer server_;
};

#endif
