/**********************************************************************
  Filename    : Camera Web Server
  Description : The camera images captured by the ESP32S3 are displayed on the web page.
  Auther      : www.freenove.com
  Modification: 2024/07/01
**********************************************************************/
#include "esp_camera.h"
#include <WiFi.h>

// ===================
// Select camera model
// ===================
//#define CAMERA_MODEL_WROVER_KIT // Has PSRAM
//#define CAMERA_MODEL_ESP_EYE // Has PSRAM
#define CAMERA_MODEL_ESP32S3_EYE // Has PSRAM
//#define CAMERA_MODEL_M5STACK_PSRAM // Has PSRAM
//#define CAMERA_MODEL_M5STACK_V2_PSRAM // M5Camera version B Has PSRAM
//#define CAMERA_MODEL_M5STACK_WIDE // Has PSRAM
//#define CAMERA_MODEL_M5STACK_ESP32CAM // No PSRAM
//#define CAMERA_MODEL_M5STACK_UNITCAM // No PSRAM
//#define CAMERA_MODEL_AI_THINKER // Has PSRAM
//#define CAMERA_MODEL_TTGO_T_JOURNAL // No PSRAM
// ** Espressif Internal Boards **
//#define CAMERA_MODEL_ESP32_CAM_BOARD
//#define CAMERA_MODEL_ESP32S2_CAM_BOARD
//#define CAMERA_MODEL_ESP32S3_CAM_LCD

#include "camera_pins.h"

// ===========================
// Enter your WiFi credentials
// ===========================
const char* ssid     = "goads_driver";
const char* password = "12345678";

void startCameraServer();

void setup() {
  Serial.begin(115200);
  // Optimized: Disable debug output for better performance (can enable for debugging)
  Serial.setDebugOutput(false);  // Set to false to reduce overhead
  Serial.println();

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  // Optimized for ESP32-S3: Balanced XCLK frequency
  config.xclk_freq_hz = 16000000;  // 16MHz - stable for ESP32-S3
  // CRITICAL: Reduced resolution from SVGA (800x600) to VGA (640x480) for much faster streaming
  config.frame_size = FRAMESIZE_VGA;  // Changed from SVGA to VGA - 4x less pixels!
  config.pixel_format = PIXFORMAT_JPEG; // for streaming
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 8;  // Lower quality for faster encoding
  config.fb_count = 2;
  
  // if PSRAM IC present, init with optimized settings for streaming
  if(psramFound()){
    // CRITICAL: Very low JPEG quality (5-8) for fastest encoding and smallest frames
    config.jpeg_quality = 5;  // Very low quality but much faster
    // Optimized: Increase buffer count for smoother streaming
    config.fb_count = 3;  // Increased from 2 to 3 for better buffering
    config.grab_mode = CAMERA_GRAB_LATEST;  // Always use latest frame
  } else {
    // Limit the frame size when PSRAM is not available
    config.fb_count = 1;
    config.fb_location = CAMERA_FB_IN_DRAM;
    config.frame_size = FRAMESIZE_QVGA;  // Even smaller if no PSRAM
  }

  // camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  sensor_t * s = esp_camera_sensor_get();
  // initial sensors are flipped vertically and colors are a bit saturated
  s->set_vflip(s, 1); // flip it back
  s->set_brightness(s, 1); // up the brightness just a bit
  s->set_saturation(s, 0); // lower the saturation
  
  // Optimized: Disable unnecessary camera features for faster processing
  s->set_gain_ctrl(s, 1);  // Auto gain control ON (AGC)
  s->set_whitebal(s, 1);  // Auto white balance ON (AWB)
  s->set_exposure_ctrl(s, 1);  // Auto exposure ON (AEC)
  s->set_aec2(s, 0); // AEC2 OFF for faster processing
  s->set_dcw(s, 1);  // Downsize EN
  s->set_bpc(s, 0);  // BPC OFF - faster
  s->set_wpc(s, 1);  // WPC ON
  s->set_raw_gma(s, 1); // Raw GMA ON
  s->set_lenc(s, 0); // Lens correction OFF - faster
  
  // CRITICAL: Optimize WiFi for ESP32-S3 streaming performance
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);  // Disable WiFi sleep for consistent performance
  
  // Optimize WiFi power and channel for better throughput
  WiFi.setTxPower(WIFI_POWER_19_5dBm);  // Maximum power for better signal
  // Note: Channel selection is automatic, but you can set it if needed

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  while (WiFi.STA.hasIP() != true) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("");
  Serial.println("WiFi connected");

  startCameraServer();

  Serial.print("Camera Ready! Use 'http://");
  Serial.print(WiFi.localIP());
  Serial.println("' to connect");
}

void loop() {
  // Do nothing. Everything is done in another task by the web server
  delay(10000);
}
