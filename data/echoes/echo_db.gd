# res://data/echoes/echo_db.gd
# Static registry for the game's echoes (残响资料库)
class_name EchoDB


static var ECHOES := {
	"echo_clerk": {
		"title": "ECHO_CLERK_TITLE",
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_CLERK_SEG_S1"
			}
		],
		"audio_path": "res://assets/audio/echoes/echo_clerk.ogg",
		"sell_price": 300,
		"comment": "ECHO_CLERK_COMMENT"
	},
	"echo_room401_tenant": {
		"title": "ECHO_ROOM401_TENANT_TITLE",
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_ROOM401_TENANT_SEG_S1"
			},
			{
				"id": "s2",
				"text": "ECHO_ROOM401_TENANT_SEG_S2"
			},
			{
				"id": "s3",
				"text": "ECHO_ROOM401_TENANT_SEG_S3"
			}
		],
		"image_path": "res://assets/images/echoes/echo_room401_tenant.png",
		"sell_price": 200,
		"comment": "ECHO_ROOM401_TENANT_COMMENT"
	},
	"echo_song_rain_doesnt_stop": {
		"title": "ECHO_SONG_RAIN_DOESNT_STOP_TITLE",
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_SONG_RAIN_DOESNT_STOP_SEG_S1"
			},
			{
				"id": "s2",
				"text": "ECHO_SONG_RAIN_DOESNT_STOP_SEG_S2"
			},
			{
				"id": "s3",
				"text": "ECHO_SONG_RAIN_DOESNT_STOP_SEG_S3"
			}
		],
		"audio_path": "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3",
		"sell_price": 150,
		"comment": "ECHO_SONG_RAIN_DOESNT_STOP_COMMENT"
	},
	"echo_lu_family": {
		"title": "ECHO_LU_FAMILY_TITLE",
		"unknown_total": true,
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_LU_FAMILY_SEG_S1"
			}
		],
		"sell_price": 0,
		"comment": "ECHO_LU_FAMILY_COMMENT"
	},
	"echo_settlement_erased": {
		"title": "ECHO_SETTLEMENT_ERASED_TITLE",
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_SETTLEMENT_ERASED_SEG_S1"
			},
			{
				"id": "s2",
				"text": "ECHO_SETTLEMENT_ERASED_SEG_S2"
			}
		],
		"sell_price": 250,
		"comment": "ECHO_SETTLEMENT_ERASED_COMMENT"
	},
	"echo_ada_reset": {
		"title": "ECHO_ADA_RESET_TITLE",
		"segments": [
			{
				"id": "s1",
				"text": "ECHO_ADA_RESET_SEG_S1"
			}
		],
		"image_path": "res://assets/images/echoes/echo_ada_reset.jpeg",
		"sell_price": 300,
		"comment": "ECHO_ADA_RESET_COMMENT",
		"trace_on_collect": 1
	},
	"echo_linfei": {
		"title": "ECHO_LINFEI_TITLE",
		"segments": [
			{"id": "s1", "text": "ECHO_LINFEI_SEG_S1"},
			{"id": "s2", "text": "ECHO_LINFEI_SEG_S2"},
			{"id": "s3", "text": "ECHO_LINFEI_SEG_S3"},
			{"id": "s4", "text": "ECHO_LINFEI_SEG_S4"},
			{"id": "s5", "text": "ECHO_LINFEI_SEG_S5"},
			{"id": "s6", "text": "ECHO_LINFEI_SEG_S6"}
		],
		"media_slots": {
			"audio": {
				"threshold": 3,
				"path": ""
			},
			"image": {
				"threshold": 6,
				"path": "res://assets/images/echoes/echo_linfei.jpeg"
			}
		},
		"sell_price": 400,
		"comment": "ECHO_LINFEI_COMMENT",
		"trace_on_collect": 1
	}
}

static func get_echo(echo_id: String) -> Dictionary:
	return ECHOES.get(echo_id, {})

static func get_segment_count(echo_id: String) -> int:
	var echo = get_echo(echo_id)
	if echo.is_empty():
		return 0
	return echo.get("segments", []).size()

static func has_echo(echo_id: String) -> bool:
	return ECHOES.has(echo_id)
