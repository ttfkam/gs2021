<script context="module" lang="ts">
	import { getDayBeforeAndDayAfter } from '$lib/date-slug';
	export function EpisodeVariables({ params }) {
		//TODO - get a query that does not require a range to get an episode by date
		let { year, month, day } = params;
		const today = new Date(`${year}-${month}-${day}`);
		return getDayBeforeAndDayAfter(today);
	}
</script>

<script lang="ts">
	import { query, graphql } from '$houdini';
	import type { Episode } from '$houdini';
	const { data, error, loading } = query<Episode>(graphql`
		query Episode($pStart: Date!, $pEnd: Date!) {
			episodesByAirdateList(pStart: $pStart, pEnd: $pEnd) {
				id
				airdate
				title
				status
				summary
				geekBitsList(orderBy: [ID_ASC]) {
					title
					status
					body
					link {
						summary
					}
				}
			}
		}
	`);
</script>

{#if $data && $data.episodesByAirdateList && $data.episodesByAirdateList[0]}
	<div>
		<h2>{$data.episodesByAirdateList[0].title}</h2>
		<p>{$data.episodesByAirdateList[0].summary}</p>
		<ul>
			{#each $data.episodesByAirdateList[0].geekBitsList as bit}
				<li>{bit.title}</li>
			{/each}
		</ul>
	</div>
{/if}
