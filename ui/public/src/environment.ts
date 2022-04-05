import { Environment } from '$houdini';
import config from '../houdini.config';

import { env } from './variables';
export default new Environment(async function ({ text, variables = {} }) {
	// send the request to the api

	console.log(config.apiUrl);
	const result = await this.fetch(config.apiUrl, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({
			query: text,
			variables
		})
	});

	// parse the result as json
	return await result.json();
});
