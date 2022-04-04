/** @type {import('houdini').ConfigFile} */
const config = {
	schemaPath: './schema.graphql',
	sourceGlob: 'src/**/*.svelte',
	module: 'esm',
	framework: 'kit',
	apiUrl: 'http://localhost:3000/graphql',
	scalars: {
		UUID: {
			type: 'string',
			unmarshal(val) {
				return val;
			},
			// turn the value into something the API can use
			marshal(val) {
				return val;
			}
		},
		Date: {
			// the corresponding typescript type
			type: 'Date',
			// turn the api's response into that type
			unmarshal(val) {
				return val;
			},
			// turn the value into something the API can use
			marshal(date) {
				return date;
			}
		},
		Datetime: {
			// the corresponding typescript type
			type: 'Date',
			// turn the api's response into that type
			unmarshal(val) {
				return new Date(val);
			},
			// turn the value into something the API can use
			marshal(date) {
				return date.getTime();
			}
		},
		Cursor: {
			type: 'string',
			unmarshal(val) {
				return val;
			},
			// turn the value into something the API can use
			marshal(val) {
				return val;
			}
		}
	}
};

export default config;
