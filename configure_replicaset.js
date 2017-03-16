db = (new Mongo('localhost:27000')).getDB('test')
config = {
	"_id" : "epic",
	"members" : [
		{
			"_id" : 0,
			"host" : "epic_primary:27017"
		},
		{
			"_id" : 1,
			"host" : "epic_sec_1:27017"
		},
		{
			"_id" : 2,
			"host" : "epic_sec_2:27017"
		},
		{
			"_id" : 3,
			"host" : "epic_sec_3:27017"
		},
	]
}
rs.initiate(config)
