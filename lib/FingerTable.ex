defmodule FingerTable do
	
	def generate(pid_N_map, m) do
		
		nodes = Enum.sort(Map.values pid_N_map)
		IO.puts nodes

		Enum.each pid_N_map, fn {pid, n} ->

				fingertable = Enum.reduce(0..m-1, %{}, fn i, acc->
					 fingertable_val = rem(n + :math.pow(2, i) |> Kernel.trunc, :math.pow(2, m) |> Kernel.trunc)
					 nodes_greater = Enum.filter(nodes, fn x -> x>=fingertable_val 
										end)
					 min_greater_node =
					 	if nodes_greater == [] do
					 		Enum.min nodes
					 	else
					 		Enum.min nodes_greater
					 	end
					 Map.put acc, i, min_greater_node
				end)
				ChordNodeCoordinator.set_fingertable(pid, fingertable)
				# IO.inspect fingertable
		end
	end
end