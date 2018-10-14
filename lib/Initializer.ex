defmodule Initalizer do

	@m 8

	def start do
		args = System.argv()
	    numNodes = String.to_integer(Enum.at(args, 0))     
	    numRequests = String.to_atom(Enum.at(args, 1))     
	    IO.puts "

	    #########################################

	    		numNodes    : #{numNodes}
	    		numRequests : #{numRequests}

	    #########################################
	    "
	    :timer.sleep 3000
	    IO.puts "Initializing chord with #{numNodes} and starting #{numRequests}"
	    :timer.sleep 3000
	    __init__ numNodes	    
	end

	defp __init__(numNodes) do

		AppSupervisor.start_link
		initNnodes numNodes
	end

	#Initializing the stabilizer supervisor
	defp __init__stabilizer__ (pid_N_map) do
		AppSupervisor.StabilizerSupervisor.start_link
		ChordStabilizer.start pid_N_map
	end

	#Initializing numNodes in one go
	defp initNnodes(numNodes) do
		
		Enum.map(1..numNodes, fn _ -> Supervisor.start_child(:ChordSupervisor, []) end)
		child_pids = Supervisor.which_children(:ChordSupervisor) |> Enum.map( fn item -> elem(item, 1) end)
		IO.inspect child_pids
		pid_N_map = generateRing child_pids
		ChordOperations.initializeSuccessors pid_N_map
		ChordOperations.initializePredecessors pid_N_map
		__init__stabilizer__ pid_N_map
		:timer.sleep 10000
		# Generate numNodes*2 number of keys
		# ChordOperations.printFingerTables pid_N_map
		# generateStorePrintKeys numNodes*2, pid_N_map
		ChordOperations.node_join @m, pid_N_map
	end

	#Join numNodes-1 remaining nodes to the chord ring
	defp joinRemnodes(numNodes) do

		{:ok, pid}  = Supervisor.start_child(:ChordSupervisor, [])
		hash_pid = HashGenerator.hash @m, Kernel.inspect pid
		pid_N_map = %{pid => hash_pid}		
		Enum.each 1..numNodes-1, fn _ -> ChordOperations.node_join @m, pid_N_map end
	end

	defp generateRing(child_pids) do

		pid_N_map = Enum.reduce(child_pids, %{}, fn pid, acc -> 
								Map.put(acc, pid, HashGenerator.hash(@m, Kernel.inspect pid))
								end)
		IO.inspect pid_N_map
		FingerTable.generate pid_N_map, @m
		ChordOperations.printFingerTables pid_N_map
		pid_N_map
	end

	defp generateStorePrintKeys(numKeys, pid_N_map) do
		keys = KeyGen.generateKeys numKeys, @m
		IO.inspect "generated keys ===== #{inspect keys}"
		:timer.sleep 3000
		ChordOperations.storeKeys keys, pid_N_map
		IO.puts ":store_key in progress ...."
		:timer.sleep 12000
		ChordOperations.printKeys pid_N_map
		:timer.sleep 10000
	end
end
Initalizer.start

