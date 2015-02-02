package require PWI_Glyph 2.17.2

# Run script on selected domains if there are any.
set mask [pw::Display createSelectionMask -requireDomain {Defined}]
pw::Display getSelectedEntities -selectionmask $mask domains

set nDomains [llength $domains(Domains)]

# If no domains were selected at runtime, ask user to select them.
if {$nDomains == 0} {
  # Create selection mask for domains.
  set domainMask [pw::Display createSelectionMask -requireDomain Defined]

  if {![pw::Display selectEntities -selectionmask $domainMask \
      -description "Select domains for extrusion" domains] } {
    set domains(Domains) ""
  }
}

set nDomains [llength $domains(Domains)]

puts "Selected $nDomains [expr ($nDomains==1)?"Domain":"Domains"] for extrusion..."

# Create selection mask for connector for extrusion path.
set connectorMask [pw::Display createSelectionMask -requireConnector Dimensioned]

if {![pw::Display selectEntities -selectionmask $connectorMask \
    -description "Select connector for extrusion path" path] } {
  set path(Connectors) ""
}

if {[llength $path(Connectors)] != 1} {
  error "Select only one connector for the extrusion path"
}

set extrusionPath $path(Connectors)
puts "Selected [$extrusionPath getName] for extrusion path... Dimension: [$extrusionPath getDimension]"

# Extrude a domain at a time.
foreach dom $domains(Domains) {

  # Extract information from the boundary conditions.
  set BCName [[$dom getAutomaticBoundaryCondition] getName]

  # Extract number from boundary condition; to be incremented.
  # The boundary condition is expected to have the form: xxxxx##_##### where
  # 'x' represents any upper or lowercase letter (a through z) and '#' is a
  # number.  This number will be incremented by one and applied to the extruded
  # block.  There may be any number of letters an numbers as long as they are
  # separated by an underscore (_).
  regexp {([a-zA-Z]*[0-9]+_)([0-9]*)} $BCName all prefix number
  #puts "all: $all"
  #puts "prefix: $prefix"
  #puts "number: $number"
  #puts "number plus one [expr $number + 1]"
  if {$number == ""} {
    error "Error parsing boundary conditions: did not find a number"
  }

  puts "extruding domain $dom; BCName: $BCName"

  set createExtrusionMode [pw::Application begin Create]
  # Create the starting face of the extruded block.
  set face [pw::FaceStructured create]
  $face addDomain $dom
  set extrudedBlock [pw::BlockStructured create]
  $extrudedBlock addFace $face
  $createExtrusionMode end

  # Set up extrusion parameters.
  set extrudeMode [pw::Application begin ExtrusionSolver [list $extrudedBlock]]
  $extrudeMode setKeepFailingStep true
  $extrudedBlock setExtrusionSolverAttribute Mode Path
  $extrudedBlock setExtrusionSolverAttribute PathConnectors [list $extrusionPath]
  $extrudedBlock setExtrusionSolverAttribute PathUseTangent 1

  # Run the extrusion along the specified path.
  $extrudeMode run [expr [$extrusionPath getDimension] - 1]
  $extrudeMode end

  # Extract and name Unspecified boundary conditions. This is hacky, but it
  # allows for me to used this data to repeat this extrusion process from the
  # front created by the script.
  set UnspecifiedDoms []
  for {set iFace 1} {$iFace <= [$extrudedBlock getFaceCount]} {incr iFace} {
    set face [$extrudedBlock getFace $iFace]
    set ds [$face getDomains]
    set bcName [[$ds getAutomaticBoundaryCondition] getName]

    # Collect list of Unspecified boundaries.
    if {$bcName == "Unspecified"} {
      lappend UnspecifiedDoms $ds
    }
  }

  # Create the new boundary and volume condition.
  set bc [pw::BoundaryCondition create]
  # Create new boundary/volume condition name by incrementing the old number.
  set newName $prefix[expr $number + 1]
  #puts "newName: $newName"
  $bc setName $newName
  foreach b $UnspecifiedDoms {
    $bc apply [list $extrudedBlock $b]
  }
  set vc [pw::VolumeCondition create]
  $vc setName $newName
  $vc apply $extrudedBlock
}
