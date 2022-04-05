<script context="module" lang="ts">
	export async function load(ctx) {
		return { props: { route: { year: ctx.params.year } } };
	}
</script>

<script lang="ts">
	export let route: { year: string };
</script>

<div>Year: {route.year}</div>
