<!DOCTYPE HTML>
<html>
	<head>
		<title>StoreIt - Contact</title>
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<meta name="description" content="" />
		<meta name="keywords" content="" />
		<link href='http://fonts.googleapis.com/css?family=Roboto:400,100,300,700,500,900' rel='stylesheet' type='text/css'>
		<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
		<script src="js/skel.min.js"></script>
		<script src="js/skel-panels.min.js"></script>
		<script src="js/init.js"></script>
		<noscript>
			<link rel="stylesheet" href="css/skel-noscript.css" />
			<link rel="stylesheet" href="css/style-desktop.css" />
		</noscript>
			<link rel="stylesheet" href="css/style.css" />
		<link rel="stylesheet" href="css/style-contact.css" />
	</head>
	<body class="homepage">

	<!-- Header -->
		<div id="header">
			<div id="nav-wrapper"> 
				<!-- Nav -->
				<nav id="nav">
					<ul>
						<li class="active"><a href="index.html">Accueil</a></li>
						<li><a href="telechargement.html">Téléchargement</a></li>
						<li><a href="teamwork.html">Qui sommes-nous</a></li>
						<li><a href="contact.php">Contact</a></li>
					</ul>
				</nav>
			</div>
			<div class="container"> 
				
				<!-- Logo -->
				<div id="logo">
					<h1><a href="#"></a></h1>
				</div>
			</div>
		</div>

		
	<!-- Main -->
		<div id="main">
<?php
  session_start();
  ?>
  <div >
  <?php if(array_key_exists('errors',$_SESSION)): ?>
  <div class="alert alert-danger">
  <?= implode('<br>', $_SESSION['errors']); ?>
  </div>
  <?php endif; ?>
  <?php if(array_key_exists('success',$_SESSION)): ?>
  <div class="alert alert-success">
  Votre email à bien été transmis !
  </div>
  <?php endif; ?>

			<div id="content" class="container">
				<section>
					<div class='center'>
						<div class='center1'>
					  <div class='title'>
					    <h1>Envoyez-nous un message !</h1>
					  </div>

       					<form class="clearfix" action="send_form.php" method="post">

						<div class='name'>
					    	<input type="text" name="firstname" id "inputname" class="first" placeholder="Prénom" value="<?php echo isset($_SESSION['inputs']['name'])? $_SESSION['inputs']['name'] : ''; ?>">
					    	<input type="text" name="name" id "inputname" class="last" placeholder="Prénom" value="<?php echo isset($_SESSION['inputs']['name'])? $_SESSION['inputs']['name'] : ''; ?>">
						</div>
						<div class='contact'>
        					<input type="text" id="inputemail" name ="email" class="email" placeholder="E-mail" value="<?php echo isset($_SESSION['inputs']['email'])? $_SESSION['inputs']['email'] : ''; ?>">
						</div>
						<div class='message'>
        					<textarea class="message" id="inputmessage" name ="message" placeholder="Votre message"><?php echo isset($_SESSION['inputs']['message'])? $_SESSION['inputs']['message'] : ''; ?></textarea>
						</div>
						<div class="end">
						   <button>Envoyer</button>
						</div>


     					 </form>
     					 </div>
					</div>
					</section>
			</div>
		</div>
		</div>
	<!-- /Main -->

	<!-- Tweet -->
		<div id="tweet">
			<div class="container">
				<section>
					<blockquote>&ldquo;Parce que partager est une forme de liberté.&rdquo;</blockquote>
					<span> Citation d'un inconnu </span>
				</section>
			</div>
		</div>
	<!-- /Tweet -->

	<!-- Footer -->
		<div id="footer">
			<div class="container">
				<section>
					<header>
						<h2>Suivez-nous</h2>
						<span class="byline">Suivez notre projet sur les réseaux sociaux</span>
					</header>
					<ul class="contact">
						<li><a href="https://twitter.com/StoreItproject" class="fa fa-twitter" target="_blank"><span>Twitter</span></a></li>
						<li class="active"><a href="https://www.facebook.com/storeItproject/" class="fa fa-facebook" target="_blank"><span>Facebook</span></a></li>
						<li><a href="https://plus.google.com/u/0/116863813896847432481/posts?hl=fr" class="fa fa-google-plus" target="_blank"><span>Google+</span></a></li>
					</ul>
				</section>
			</div>
		</div>

	<!-- Copyright -->
		<div id="copyright">
			<div class="container">
				Designed by StoreIt || Contact : <a href="contact.storeit@gmail.com">contact.storeit@gmail.com</a>
			</div>
		</div>

	</body>
</html>

  <?php
unset($_SESSION['inputs']); // on nettoie les données précédentes
  unset($_SESSION['success']);
  unset($_SESSION['errors']);
  ?>