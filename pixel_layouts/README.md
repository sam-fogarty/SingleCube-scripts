Pixel layout yamls are needed for accessing pixel yz positions. They are also inputs for larnd-sim and module0_flow. The yamls are generated using larpix-geometry.

To make single_tile_layout for SingleCube:
Run `python larpixgeometry/layouts/layout-2.4.0.py`

Run `python multi_tile_layout.py layout-2.4.0.yaml ndlar_network/network-10x10-tile-singlecube.json`

This makes the single-tile layout (may need to rename appropriately). I changed tile_positions to {1: [-304.31, 0, 0]} for SingleCube. Need to further validate this pixel layout file.

For new versions, iterate second number in X.Y.Z. version.