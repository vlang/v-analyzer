module types

import json

struct JsonData {}

fn main() {
	data := ''

	res := json.decode(JsonData, data)
	expr_type(res, '!types.JsonData')

	res2 := json.decode([]JsonData, data)
	expr_type(res2, '![]types.JsonData')

	res3 := json.decode(map[string]JsonData, data)
	expr_type(res3, '!map[string]types.JsonData')

	if res4 := json.decode(map[string]JsonData, data) {
		expr_type(res4, 'map[string]types.JsonData')
	}
}
