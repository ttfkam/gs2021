import preprocess from 'svelte-preprocess';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: preprocess(),

	kit: {
		// hydrate the <div id="svelte"> element in src/app.html
		target: '#svelte',
		vite: {
			server: {
				host: '0.0.0.0',
				hmr: {
					host: 'localhost',
					protocol: 'ws',
					port: 15001,
				}
			}
		}
	}
};

export default config;
