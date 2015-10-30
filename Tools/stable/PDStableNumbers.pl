# renumber PowerDesigner XML files to help their comparison / version control
#
# TODO
#  add license
#  update file in place, or as a filter
#  update using XML input, or parameter file
#  generate parameter file
#  option to update parameter file, or always
#  function to retrieve numbers for a PD model
#  function to check for a correct XML PD model
#  function to read a parameter file
#
# support entity ids/refs, with identified objects:
#   <o:EntitySymbol Id="o12">
#   <o:Entity Ref="o16"/>
#   <a:ObjectID>1003CE24-C7F0-4A08-BD64-84D259FA0596</a:ObjectID>

   use strict;
