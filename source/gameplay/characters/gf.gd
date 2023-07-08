extends Character

var lastAnim="";

func onBeat(beat):
	var idle="dance%s"%[(["Left","Right"][int(beat)%2])];
	
	if anims.current_animation=="":
		anims.play(idle);
	
	if anims.current_animation==idle:
		idle="dance%s"%[(["Left","Right"][int(beat+1)%2])];
		anims.play(idle);
		anims.seek(0.0);
