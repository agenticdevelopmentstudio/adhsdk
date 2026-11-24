from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_event_cost_type_0 import GameEventCostType0
    from ..models.game_event_input_type_0 import GameEventInputType0
    from ..models.game_event_output_type_0 import GameEventOutputType0


T = TypeVar("T", bound="GameEvent")


@_attrs_define
class GameEvent:
    """
    Attributes:
        id (str):
        session_id (str):
        kind (str):
        seq (int):
        client_event_id (str):
        occurred_at (str):
        input_ (GameEventInputType0 | None | Unset):
        output (GameEventOutputType0 | None | Unset):
        cost (GameEventCostType0 | None | Unset):
        artifact_id (None | str | Unset):
    """

    id: str
    session_id: str
    kind: str
    seq: int
    client_event_id: str
    occurred_at: str
    input_: GameEventInputType0 | None | Unset = UNSET
    output: GameEventOutputType0 | None | Unset = UNSET
    cost: GameEventCostType0 | None | Unset = UNSET
    artifact_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_event_cost_type_0 import GameEventCostType0
        from ..models.game_event_input_type_0 import GameEventInputType0
        from ..models.game_event_output_type_0 import GameEventOutputType0

        id = self.id

        session_id = self.session_id

        kind = self.kind

        seq = self.seq

        client_event_id = self.client_event_id

        occurred_at = self.occurred_at

        input_: dict[str, Any] | None | Unset
        if isinstance(self.input_, Unset):
            input_ = UNSET
        elif isinstance(self.input_, GameEventInputType0):
            input_ = self.input_.to_dict()
        else:
            input_ = self.input_

        output: dict[str, Any] | None | Unset
        if isinstance(self.output, Unset):
            output = UNSET
        elif isinstance(self.output, GameEventOutputType0):
            output = self.output.to_dict()
        else:
            output = self.output

        cost: dict[str, Any] | None | Unset
        if isinstance(self.cost, Unset):
            cost = UNSET
        elif isinstance(self.cost, GameEventCostType0):
            cost = self.cost.to_dict()
        else:
            cost = self.cost

        artifact_id: None | str | Unset
        if isinstance(self.artifact_id, Unset):
            artifact_id = UNSET
        else:
            artifact_id = self.artifact_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "session_id": session_id,
                "kind": kind,
                "seq": seq,
                "client_event_id": client_event_id,
                "occurred_at": occurred_at,
            }
        )
        if input_ is not UNSET:
            field_dict["input"] = input_
        if output is not UNSET:
            field_dict["output"] = output
        if cost is not UNSET:
            field_dict["cost"] = cost
        if artifact_id is not UNSET:
            field_dict["artifact_id"] = artifact_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_event_cost_type_0 import GameEventCostType0
        from ..models.game_event_input_type_0 import GameEventInputType0
        from ..models.game_event_output_type_0 import GameEventOutputType0

        d = dict(src_dict)
        id = d.pop("id")

        session_id = d.pop("session_id")

        kind = d.pop("kind")

        seq = d.pop("seq")

        client_event_id = d.pop("client_event_id")

        occurred_at = d.pop("occurred_at")

        def _parse_input_(data: object) -> GameEventInputType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                input_type_0 = GameEventInputType0.from_dict(data)

                return input_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameEventInputType0 | None | Unset, data)

        input_ = _parse_input_(d.pop("input", UNSET))

        def _parse_output(data: object) -> GameEventOutputType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                output_type_0 = GameEventOutputType0.from_dict(data)

                return output_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameEventOutputType0 | None | Unset, data)

        output = _parse_output(d.pop("output", UNSET))

        def _parse_cost(data: object) -> GameEventCostType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                cost_type_0 = GameEventCostType0.from_dict(data)

                return cost_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameEventCostType0 | None | Unset, data)

        cost = _parse_cost(d.pop("cost", UNSET))

        def _parse_artifact_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        artifact_id = _parse_artifact_id(d.pop("artifact_id", UNSET))

        game_event = cls(
            id=id,
            session_id=session_id,
            kind=kind,
            seq=seq,
            client_event_id=client_event_id,
            occurred_at=occurred_at,
            input_=input_,
            output=output,
            cost=cost,
            artifact_id=artifact_id,
        )

        game_event.additional_properties = d
        return game_event

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
