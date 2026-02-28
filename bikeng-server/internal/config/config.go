package config

import (
	"sync"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	Server ServerConfig `mapstructure:"server"`
	MySQL  MySQLConfig  `mapstructure:"mysql"`
	Redis  RedisConfig  `mapstructure:"redis"`
	JWT    JWTConfig    `mapstructure:"jwt"`
	SMS    SMSConfig    `mapstructure:"sms"`
	OCR    OCRConfig    `mapstructure:"ocr"`
	OSS    OSSConfig    `mapstructure:"oss"`
	FCM    FCMConfig    `mapstructure:"fcm"`
}

type ServerConfig struct {
	Port int `mapstructure:"port"`
}

type MySQLConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	DBName   string `mapstructure:"dbname"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type JWTConfig struct {
	Secret     string        `mapstructure:"secret"`
	AccessTTL  time.Duration `mapstructure:"access_ttl"`
	RefreshTTL time.Duration `mapstructure:"refresh_ttl"`
}

type SMSConfig struct {
	Aliyun SMSAliyunConfig `mapstructure:"aliyun"`
}

type SMSAliyunConfig struct {
	AccessKey    string `mapstructure:"access_key"`
	Secret       string `mapstructure:"secret"`
	SignName     string `mapstructure:"sign_name"`
	TemplateCode string `mapstructure:"template_code"`
}

type OCRConfig struct {
	Baidu OCRBaiduConfig `mapstructure:"baidu"`
}

type OCRBaiduConfig struct {
	APIKey    string `mapstructure:"api_key"`
	SecretKey string `mapstructure:"secret_key"`
}

type OSSConfig struct {
	Aliyun OSSAliyunConfig `mapstructure:"aliyun"`
}

type OSSAliyunConfig struct {
	Endpoint  string `mapstructure:"endpoint"`
	AccessKey string `mapstructure:"access_key"`
	Secret    string `mapstructure:"secret"`
	Bucket    string `mapstructure:"bucket"`
}

type FCMConfig struct {
	ServerKey string `mapstructure:"server_key"`
}

var (
	cfg  *Config
	once sync.Once
)

// LoadConfig reads the configuration file and environment variables.
func LoadConfig(configPath string) (*Config, error) {
	var err error
	once.Do(func() {
		v := viper.New()
		v.SetConfigFile(configPath)
		v.AutomaticEnv()
		v.SetEnvPrefix("BIKENG")

		if readErr := v.ReadInConfig(); readErr != nil {
			err = readErr
			return
		}

		cfg = &Config{}
		if unmarshalErr := v.Unmarshal(cfg); unmarshalErr != nil {
			err = unmarshalErr
			return
		}
	})
	return cfg, err
}

// GetConfig returns the global configuration instance.
// LoadConfig must be called before using this function.
func GetConfig() *Config {
	return cfg
}
