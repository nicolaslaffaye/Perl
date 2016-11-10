/*
 Weather forecasts for skills test.
 08 May 2015. IH. New. See WZPROC-573.

 Notes
 * From MySQL 5.6.5 any DATETIME or TIMESTAMP column can be initialised or updated
   to the current timestamp. See http://dev.mysql.com/doc/refman/5.6/en/timestamp-initialization.html.
   In the meantime create_time is populated by a trigger, but must either have a default value or
   allow NULLs for this to happen.
*/

USE test;

DROP TABLE IF EXISTS forecasts;

CREATE TABLE forecasts (
    id                                  INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique ID',
    loc_type                            VARCHAR(10)     NOT NULL COMMENT 'Location type',
    loc_code                            VARCHAR(30)     NOT NULL COMMENT 'Location code',
    loc_name                            VARCHAR(50)     NOT NULL COMMENT 'Location name',
    state                               VARCHAR(3)      NULL COMMENT 'State',
    forecast_date                       DATE            NOT NULL COMMENT 'Forecast date (ie when the forecast is for)',
    weather_icon                        VARCHAR(30)     NOT NULL COMMENT 'Weather icon phrase',
    temp_min                            DECIMAL(6,1)    NOT NULL COMMENT 'Forecast minimum temperature (�C)',
    temp_max                            DECIMAL(6,1)    NOT NULL COMMENT 'Forecast maximum temperature (�C)',
    create_time                         DATETIME        NOT NULL DEFAULT '0000-00-00' COMMENT 'Time this row was created - set to NOW() by an insert trigger',
    create_system                       VARCHAR(30)     NOT NULL COMMENT 'System in which this row was created',
    create_version                      VARCHAR(12)     NULL COMMENT 'System version',
    create_source                       VARCHAR(255)    NOT NULL COMMENT 'Source of this row, eg user name, file name, URL',
    last_update                         TIMESTAMP       NOT NULL COMMENT 'Time this row was last updated',
    update_system                       VARCHAR(30)     NULL COMMENT 'System in which this row was last updated',
    update_version                      VARCHAR(12)     NULL COMMENT 'System version',
    update_source                       VARCHAR(255)    NULL COMMENT 'Source of the latest change, eg user name, file name, URL',
    UNIQUE KEY idx_forecasts_1 ( loc_type, loc_code, forecast_date )
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*
 Default create_time to NOW()
 */

DROP TRIGGER IF EXISTS forecasts_before_insert;

delimiter $$
CREATE TRIGGER forecasts_before_insert BEFORE INSERT ON forecasts
  FOR EACH ROW BEGIN
    SET NEW.create_time = NOW();
  END;
$$

DELIMITER ;
