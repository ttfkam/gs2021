import preprocess from 'svelte-preprocess';
import houdini from 'houdini-preprocess';
import path from 'path';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: [preprocess(), houdini()],

	kit: {
		vite: {
			resolve: {
				alias: {
					$houdini: path.resolve('.', '$houdini')
				}
			},
			server: {
				hmr: {
					clientPort: 8080
				},
				fs: {
					allow: ['.']
				}
			}
		}
	}
};

export default config;
