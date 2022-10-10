Pixel layout yamls are needed for accessing pixel yz positions. They are also inputs for larnd-sim and module0_flow. The yamls are generated using larpix-geometry.

To make single_tile_layout for SingleCube:
Run `python larpixgeometry/layouts/layout-2.4.0.py' [for 10x10 pixel tile].
    Makes layout-2.4.0.yaml.
Run `python multi_tile_layout.py layout-2.4.0.yaml ndlar_network/network-tile1-tpc1.json' [defaults to ntiles=1]
    Makes multi-tile layout, rename appropriately (or change autonaming in file)

For new versions, iterate second number in X.Y.Z. version.