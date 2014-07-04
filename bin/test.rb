require "libz3"

shoes, hat, shirt, pants = [0]*4

colours = [:Blue, :Black, :Brown, :White]
always {shoes.in colours}
always {shirt.in colours}
always {pants.in colours}
always {hat.in colours}

always {shoes == hat}
always {shoes != pants}
always {shoes != shirt}
always {shirt != pants}

# Alternative
# always { (shoes == :Brown) or (shoes == :Black) }
# always { ((shirt == :Brown) or (shirt == :Blue)) or (shirt == :White) }

always { hat == :Brown }
always { shoes.one_of [:Brown, :Black] }
always { shirt.one_of [:White, :Blue, :Brown] }

print "shirt:\t#{shirt}\n"
print "shoes:\t#{shoes}\n"
print "hat:\t#{hat}\n"
print "pants:\t#{pants}\n"
