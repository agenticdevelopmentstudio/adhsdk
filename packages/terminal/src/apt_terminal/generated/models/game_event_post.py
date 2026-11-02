from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_event_post_cost import GameEventPostCost
    from ..models.game_event_post_input import GameEventPostInput
    from ..models.game_event_post_output import GameEventPostOutput


T = TypeVar("T", bound="GameEventPost")


@_attrs_define
class GameEventPost:
    """`client_event_id` is the caller’s idempotency key: reposting the same one returns the stored event and executes
    nothing.

        Attributes:
            kind (str):
            client_event_id (str):
            input_ (GameEventPostInput | Unset):
            output (GameEventPostOutput | Unset):
            cost (GameEventPostCost | Unset):
            artifact_id (str | Unset):
    """

    kind: str
    client_event_id: str
    input_: GameEventPostInput | Unset = UNSET
    output: GameEventPostOutput | Unset = UNSET
    cost: GameEventPostCost | Unset = UNSET
    artifact_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind

        client_event_id = self.client_event_id

        input_: dict[str, Any] | Unset = UNSET
        if not isinstance(self.input_, Unset):
            input_ = self.input_.to_dict()

        output: dict[str, Any] | Unset = UNSET
        if not isinstance(self.output, Unset):
            output = self.output.to_dict()

        cost: dict[str, Any] | Unset = UNSET
        if not isinstance(self.cost, Unset):
            cost = self.cost.to_dict()

        artifact_id = self.artifact_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "client_event_id": client_event_id,
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
        from ..models.game_event_post_cost import GameEventPostCost
        from ..models.game_event_post_input import GameEventPostInput
        from ..models.game_event_post_output import GameEventPostOutput

        d = dict(src_dict)
        kind = d.pop("kind")

        client_event_id = d.pop("client_event_id")

        _input_ = d.pop("input", UNSET)
        input_: GameEventPostInput | Unset
        if isinstance(_input_, Unset):
            input_ = UNSET
        else:
            input_ = GameEventPostInput.from_dict(_input_)

        _output = d.pop("output", UNSET)
        output: GameEventPostOutput | Unset
        if isinstance(_output, Unset):
            output = UNSET
        else:
            output = GameEventPostOutput.from_dict(_output)

        _cost = d.pop("cost", UNSET)
        cost: GameEventPostCost | Unset
        if isinstance(_cost, Unset):
            cost = UNSET
        else:
            cost = GameEventPostCost.from_dict(_cost)

        artifact_id = d.pop("artifact_id", UNSET)

        game_event_post = cls(
            kind=kind,
            client_event_id=client_event_id,
            input_=input_,
            output=output,
            cost=cost,
            artifact_id=artifact_id,
        )

        game_event_post.additional_properties = d
        return game_event_post

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
