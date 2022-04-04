<script context="module" lang="ts">
	export async function load(ctx) {
		let { year, month } = ctx.params;
		return { props: { route: { year, month } } };
	}
</script>

<script lang="ts">
	export let route: { year: string; month: string };
</script>

<div>Month: {route.year}/{route.month}</div>
