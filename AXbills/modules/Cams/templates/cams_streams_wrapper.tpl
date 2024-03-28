%EXTRA_LINKS%

<div class='row'>%CAMS%</div>

<script>
  %ADDITIONAL_SCRIPT%
</script>

<script>
  jQuery('.play').on('click', function () {
    let camera = jQuery(this).data('camera');
    if (!camera) return;

    let loader = jQuery(this).parent().find('.loader');

    jQuery(this).addClass('d-none');
    loader.removeClass('d-none');

    let self = this;
    jQuery.post('$SELF_URL', { header: 2, qindex: '$index', camera: camera, AJAX: 1 }, function (result) {
      jQuery(self).parent().html(result);
    });
  });
</script>

<style>
	.stroke-solid {
		stroke-dashoffset: 0;
		stroke-dashArray: 300;
		stroke-width: 2px;
		transition: stroke-dashoffset 1s ease,
		opacity 1s ease;
	}

	.icon {
		transform: scale(.8);
		transform-origin: 50% 50%;
		transition: transform 200ms ease-out;
	}

	.play:hover .stroke-solid {
		opacity: 1;
		stroke-dashoffset: 300;
	}

	.play:hover .icon {
		transform: scale(.9);
	}

	.play:active .icon {
		transform: scale(.8);
	}

	.loader {
		position: relative;
		margin: 0px auto;
		width: 100px;
		height:100px;
	}
	.loader:before {
		content: '';
		display: block;
		padding-top: 100%;
	}

	.circular-loader {
		-webkit-animation: rotate 2s linear infinite;
		animation: rotate 2s linear infinite;
		height: 100%;
		-webkit-transform-origin: center center;
		-ms-transform-origin: center center;
		transform-origin: center center;
		width: 100%;
		position: absolute;
		top: 0;
		left: 0;
		margin: auto;
	}

	.loader-path {
		stroke-dasharray: 150,200;
		stroke-dashoffset: -10;
		-webkit-animation: dash 1.5s ease-in-out infinite, color 6s ease-in-out infinite;
		animation: dash 1.5s ease-in-out infinite, color 6s ease-in-out infinite;
		stroke-linecap: round;
	}

	@-webkit-keyframes rotate {
		100% {
			-webkit-transform: rotate(360deg);
			transform: rotate(360deg);
		}
	}

	@keyframes rotate {
		100% {
			-webkit-transform: rotate(360deg);
			transform: rotate(360deg);
		}
	}
	@-webkit-keyframes dash {
		0% {
			stroke-dasharray: 1,200;
			stroke-dashoffset: 0;
		}
		50% {
			stroke-dasharray: 89,200;
			stroke-dashoffset: -35;
		}
		100% {
			stroke-dasharray: 89,200;
			stroke-dashoffset: -124;
		}
	}
	@keyframes dash {
		0% {
			stroke-dasharray: 1,200;
			stroke-dashoffset: 0;
		}
		50% {
			stroke-dasharray: 89,200;
			stroke-dashoffset: -35;
		}
		100% {
			stroke-dasharray: 89,200;
			stroke-dashoffset: -124;
		}
	}
	@-webkit-keyframes color {
		0% {
			stroke: #007bff;
		}
		40% {
			stroke: #007bff;
		}
		66% {
			stroke: #007bff;
		}
		80%, 90% {
			stroke: #007bff;
		}
	}
	@keyframes color {
		0% {
			stroke: #007bff;
		}
		40% {
			stroke: #007bff;
		}
		66% {
			stroke: #007bff;
		}
		80%, 90% {
			stroke: #007bff;
		}
	}

</style>