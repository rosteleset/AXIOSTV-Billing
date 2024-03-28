<div class='container'>
  <div class='row align-items-start p-1'>
    <div class='col-md-6 align-self-center %DISPLAY_BLOCKS% %BLOCKS_COL%'>
      <div class='custom-row'>
        <div class='custom-col'>
          <div class='custom-content h-100 card-info'>
            <h4 class='h4 mb-0'>_{NEW_TICKETS}_</h4>
            <small class='text-muted text-bold'>%ADMIN%</small>
            <h1 class='text-warning text-bold title text-center'>%TOTAL_TICKETS%</h1>
          </div>
        </div>
        <div class='custom-col'>
          <div class='custom-content h-100 card-info'>
            <h4 class='h4 mb-0'>_{REPLYS}_</h4>
            <small class='text-muted text-bold'>%ADMIN%</small>
            <h1 class='text-danger text-bold title text-center'>%TOTAL_REPLIES%</h1>
          </div>
        </div>
      </div>
      <div class='custom-row'>
        <div class='custom-col'>
          <div class='custom-content h-100 card-info'>
            <h4 class='h4 mb-0'>_{CLOSED}_</h4>
            <small class='text-muted text-bold'>%ADMIN%</small>
            <h1 class='text-indigo text-bold title text-center'>%CLOSED_TICKETS%</h1>
          </div>
        </div>
        <div class='custom-col'>
          <div class='custom-content h-100 card-info'>
            <h4 class='h4 mb-0'>_{AVERAGE_RATING}_</h4>
            <div class='h4 text-center mt-3'>%RATING%</div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-6 border-55 bg-white %DISPLAY_CHART% %CHART_COL%'>
      %CHART%
    </div>
  </div>
</div>

<style>
	.custom-row {
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		margin-bottom: 20px;
	}

	.custom-col {
		width: calc(50% - 10px);
	}

	.custom-content {
		padding: 10px;
		border: 1px solid #ddd;
		border-radius: 10px;
		text-align: left
	}

	.card-info {
		min-height: 9rem;
		background-color: white;
		box-shadow: 0 0 1px rgba(0, 0, 0, .125), 0 1px 3px rgba(0, 0, 0, .2);
	}

	.dark-mode .card-info {
		background-color: #343a40;
	}

	.title {
		font-size: 3.5rem !important;
	}
</style>