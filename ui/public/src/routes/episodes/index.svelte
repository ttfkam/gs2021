<script lang="ts">
	import { query, graphql } from '$houdini';
	import type { Episodes } from '$houdini';
	const { data } = query<Episodes>(graphql`
		query Episodes {
			episodesList(first: 10, orderBy: AIRDATE_DESC) {
				id
				title
				summary
				airdate
				geekBits {
					totalCount
				}
			}
		}
	`);
	console.log(data);

	function toSlug(airdate) {
		let d = new Date(airdate);
		let month = (d.getMonth() + 1).toString().padStart(2, '0');
		let day = (d.getDate() + 1).toString().padStart(2, '0');
		let year = d.getFullYear();
		return [year, month, day].join('/');
	}
</script>

<div>
	We have episodes

	{#if $data && $data.episodesList}
		{#each $data.episodesList as episode, index}
			<div>
				<a href={`/episodes/${toSlug(episode.airdate)}/`}>{episode.airdate}</a>
				<h2>{episode.title}</h2>
				<p>{episode.summary}</p>
			</div>
		{/each}
	{/if}
</div>
