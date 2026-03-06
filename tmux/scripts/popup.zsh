#!/usr/bin/env zsh

_session_name_centered='centered'
_session_name_dropdown='dropdown'

_session_name_current="$(tmux display-message -p -F "#{session_name}")";
_session_name_disired="${1:-${_session_name_centered}}";

# set popup dimensions depending on the desired session name
case "${_session_name_disired}" in
	("${_session_name_centered}")
		_popup_width="${2:-70}"
		_popup_height="${3:-67}"
		;;
	("${_session_name_dropdown}")
		_popup_width="${2:-80}"
		_popup_height="${3:-75}"
		;;
	(*)
		_popup_width="${2:-70}"
		_popup_height="${3:-67}"
		;;
esac

# detach current session in case it is a popup session
case "${_session_name_current}" in
	("${_session_name_centered}"|"${_session_name_dropdown}")
		# we are in popup session -> detach
		tmux detach-client
		case "${_session_name_current}" in
			("${_session_name_disired}")
				# user has asked to detach from current session
				# -> we are done here; no need to open a popup session
				return
				;;
			(*)
				;;
		esac
		;;
	(*)
		;;
esac

# open (if necessary create new) popup session
case "${_session_name_disired}" in
	("${_session_name_centered}")
		tmux display-popup \
			-d '#{pane_current_path}' \
			-h ${_popup_height}% \
			-w ${_popup_width}% \
			-E "tmux new-session -As ${_session_name_disired}"
		;;
	("${_session_name_dropdown}")
		tmux display-popup \
			-d '#{pane_current_path}' \
			-h ${_popup_height}% \
			-w ${_popup_width}% \
			-y "#{popup_pane_top}" \
			-E "tmux new-session -As ${_session_name_disired}"
		;;
	(*)
		;;
esac
