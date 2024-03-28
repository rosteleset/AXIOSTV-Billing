<style>
	tfoot > tr > th:nth-child(2),
	tr > td:not([rowspan]):not([colspan]):first-child,
	tr.text-right > td:first-child[rowspan] ~ td:nth-child(2) {
		position: sticky;
		left: 40px;
		background: white;
	}

	td.skip,
	tfoot > tr > th:first-child,
	tbody > tr:first-child > td:first-child {
		position: sticky !important;
		left: 0 !important;
		background: white;
	}

	table {
		border-collapse: separate;
		border-spacing: 0;
	}

	.table-responsive {
		display: block;
		max-height: 80vh;
	}

	tr.bg-inherit:first-child {
		position: sticky !important;
		top: 0 !important;
		z-index: 1;
		background: white !important;
	}

	tr.bg-inherit:nth-child(2) {
		position: sticky !important;
		top: 36px !important;
		background: white !important;
	}

	tr.bg-inherit:nth-child(3) {
		position: sticky !important;
		top: 72px !important;
		background: white !important;
	}

	tr.bg-inherit:nth-child(4) {
		position: sticky !important;
		top: 107px !important;
		background: white !important;
	}
</style>