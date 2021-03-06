<?

class eZBotrVideo
{
    /*!
     Constructor
    */
    function eZBotrVideo( $id )
    {
        $this->ID = $id;
		$ini = new eZINI('botr.ini');
		$Key = $ini->variable('BOTRSettings', 'Key');
		$Private = $ini->variable('BOTRSettings', 'Private');
		$botr_api = new Botr_API($Key,$Private);
		$player_results = $botr_api->call('/players/list');
		$this->Players = array();
		if (array_key_exists('players', $player_results) ) {
			foreach ($player_results['players'] as $p) {
				$this->Players[$p['key']] = $p;
			}
		}
		
		if ($id == '') {
			$this->Attributes = array('conversion' => '', 'html'=>"<p>No video currently loaded.</p>", 'video_key' => $id, 'response' => array(false, false), 'download' => '/content/error/404');
		} else {
		
            $timestamp = time();
            $month_start = strtotime(date('Y-m-01 00:00:00', $timestamp));
            $month_end  = strtotime(date('Y-m-t 23:59:59', $timestamp));
            $delivery_data = $botr_api->call('/accounts/usage/show', array('account_key' => $Key, 'start_date' => $month_start, 'end_date' => $month_end, 'aggregate'=> true));
            $storage_data = $botr_api->call('/accounts/usage/show', array('account_key' => $Key, 'aggregate'=> true));
            $storage = $this->sizeFilter($storage_data['account']['storage']['used']);
            $delivery = $this->sizeFilter($delivery_data['account']['delivery']['used']);
			$response1 = $botr_api->call('/videos/show', array('video_key'=>$id));
			$response2 = $botr_api->call('/videos/conversions/list', array('video_key'=>$id));

			if ($response1['video']['status'] != 'ready') {
			
				$this->Attributes = array('conversion' => '', 'html'=>"<p>Your video has been uploaded. Conversion details will appear shortly.</p>", 'video_key' => $id, 'response' => array($response1, $response2), 'download' => '/content/error/404');
			
			} else {

				$pa = $si = $du = $di = array();
		
				$vid = '/content/error/404';

				foreach ($response2['conversions'] as $c) {
					$tmp = $c['link']['protocol']."://".$c['link']['address'].$c['link']['path'];
					$pa[]=$tmp;
					if (strpos($tmp,'videos') !== false && $vid == '/content/error/404') $vid = $tmp;
					$si[]=$c['filesize'];
					$du[]=$c['duration'];
					$di[]=$c['width'] . "x" . $c['height'];
					$tmp = $c['key'];
					$se[]="<input type='radio' name='vidselect' value='$tmp'/>";
				}

				$pr = "<img src='http://cdn.thinkcreative.com/thumbs/" . $id . "-100.jpg'/>";
				$pa = implode($pa, '<br/>');
				$si = implode($si, '<br/>');
				$du = implode($du, '<br/>');
				$di = implode($di, '<br/>');
				$se = implode($se, '<br/>');

				$html = "<table class='list' cellspacing='0'><tr><th class='tight'>Preview</th><th>Path</th><th>Size</th><th>Duration</th><th>Dimensions</th></tr><tr><td>$pr</td><td>$pa</td><td>$si</td><td>$du</td><td>$di</td></tr></table>";

				$upath = preg_replace("/-[^\.]*\./", ".", $vid);

				$path = explode("/", $upath);
				$path = 'videos/' . array_pop($path);

				$path = preg_replace("/-[^\.]*\./", ".", $path);
		
		
				$expires = time() + 3600;
				$signature = md5($path.':'.$expires.':'.$Private);

				$downloadme  =  $upath.'?exp='.$expires.'&sig='.$signature;

				$this->Attributes = array('download' => $downloadme, 'html' => $html, 'response' => array($response1, $response2), 'args' => $botr_api->getargs(), 'delivery' => $delivery, 'storage' => $storage);
		
			}
		
		}
		
    }

    /*!
     Sets the name of the matrix
    */
    function setID( $id )
    {
        $this->ID = $id;
    }

    function attributes()
    {
        return array( 'id','players', 'attributes' );
    }

    function hasAttribute( $name )
    {
        return in_array( $name, $this->attributes() );
    }

    function attribute( $name )
    {
        switch ( $name )
        {
            case "id" :
            {
                return $this->ID;
            }break;
            case "players" :
            {
                return $this->Players;
            }break;
            case "attributes" :
            {
                return $this->Attributes;
            }break;
            default:
            {
                eZDebug::writeError( "Attribute '$name' does not exist", 'eZBotrVideo::attribute' );
                return null;
            }break;
        }
    }

    function sizeFilter( $bytes )
    {
        $label = array( 'B', 'KB', 'MB', 'GB', 'TB', 'PB' );
        for( $i = 0; $bytes >= 1000 && $i < ( count( $label ) -1 ); $bytes /= 1000, $i++ );
        return( round( $bytes, 2 ) . " " . $label[$i] );
    }

    public $ID;
	public $Players;
	public $Attributes;

}

?>