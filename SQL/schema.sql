-- Schema completo do banco MMA Global Dataset v3
-- Gerado automaticamente via duckdb_tables()

CREATE TABLE fighters_master(fighter_id VARCHAR, fighter_name VARCHAR, dob DATE, current_age INTEGER, height_cm DOUBLE, reach_cm DOUBLE, stance VARCHAR, nationality VARCHAR, gym VARCHAR);;

CREATE TABLE fights_career_longitudinal(fight_id VARCHAR, organization VARCHAR, event_name VARCHAR, event_date DATE, event_year INTEGER, event_location VARCHAR, weight_class VARCHAR, fighter_1 VARCHAR, fighter_2 VARCHAR, winner VARCHAR, is_title_fight BOOLEAN, winner_side INTEGER, "method" VARCHAR, method_normalized VARCHAR, method_detail VARCHAR, round_num INTEGER, time_finish_seconds INTEGER, f1_height_cm DOUBLE, f1_weight_kg DOUBLE, f2_height_cm DOUBLE, f2_weight_kg DOUBLE, height_diff_cm DOUBLE, referee VARCHAR, f1_gym VARCHAR, f2_gym VARCHAR, f1_nationality VARCHAR, f2_nationality VARCHAR, is_major_org BOOLEAN);;

CREATE TABLE fights_master_typed(fight_id VARCHAR, organization VARCHAR, event_name VARCHAR, event_date DATE, event_year INTEGER, event_location VARCHAR, weight_class VARCHAR, fighter_1 VARCHAR, fighter_2 VARCHAR, winner VARCHAR, winner_side INTEGER, is_no_contest BOOLEAN, is_title_fight_original BOOLEAN, "method" VARCHAR, method_normalized VARCHAR, method_detail VARCHAR, round_num INTEGER, time_finish_seconds INTEGER, f1_height_cm DOUBLE, f1_weight_kg DOUBLE, f1_reach_cm DOUBLE, f1_stance VARCHAR, f1_dob DATE, f2_height_cm DOUBLE, f2_weight_kg DOUBLE, f2_reach_cm DOUBLE, f2_stance VARCHAR, f2_dob DATE, f1_kd INTEGER, f1_sig_str_landed INTEGER, f1_sig_str_attempted INTEGER, f1_td_landed INTEGER, f1_td_attempted INTEGER, f1_ctrl_seconds INTEGER, f2_kd INTEGER, f2_sig_str_landed INTEGER, f2_sig_str_attempted INTEGER, f2_td_landed INTEGER, f2_td_attempted INTEGER, f2_ctrl_seconds INTEGER, f1_nationality VARCHAR, f1_gym VARCHAR, f2_nationality VARCHAR, f2_gym VARCHAR, has_stats BOOLEAN, is_title_fight BOOLEAN);;

CREATE TABLE records_career(record_id INTEGER PRIMARY KEY, rank INTEGER NOT NULL, categoria VARCHAR NOT NULL, fighter_name VARCHAR NOT NULL, valor VARCHAR NOT NULL, valor_num DOUBLE, valor_segundos INTEGER, fighter_id VARCHAR);;

CREATE TABLE records_event(record_id INTEGER PRIMARY KEY, rank INTEGER NOT NULL, categoria VARCHAR NOT NULL, event_name VARCHAR NOT NULL, event_date DATE, n_fights INTEGER, valor VARCHAR NOT NULL, valor_num DOUBLE, valor_segundos INTEGER, event_matched BOOLEAN DEFAULT(CAST('f' AS BOOLEAN)), event_signature VARCHAR);;

CREATE TABLE records_fight(record_id INTEGER PRIMARY KEY, pagina VARCHAR NOT NULL, rank INTEGER NOT NULL, categoria VARCHAR NOT NULL, fighter_a VARCHAR NOT NULL, fighter_b VARCHAR NOT NULL, event_date DATE, event_name VARCHAR, round_num INTEGER, valor VARCHAR NOT NULL, valor_num DOUBLE, valor_segundos INTEGER, fight_id VARCHAR);;

