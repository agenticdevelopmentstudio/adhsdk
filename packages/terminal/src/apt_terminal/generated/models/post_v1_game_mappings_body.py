from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GameMappingsBody")


@_attrs_define
class PostV1GameMappingsBody:
    """
    Attributes:
        game_id (str):
        from_id (str):
        kind (str):
        to_id (str):
        ecosystem_id (str | Unset):
        amount (int | Unset):
        sort_order (int | Unset):
    """

    game_id: str
    from_id: str
    kind: str
    to_id: str
    ecosystem_id: str | Unset = UNSET
    amount: int | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        game_id = self.game_id

        from_id = self.from_id

        kind = self.kind

        to_id = self.to_id

        ecosystem_id = self.ecosystem_id

        amount = self.amount

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "game_id": game_id,
                "from_id": from_id,
                "kind": kind,
                "to_id": to_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if amount is not UNSET:
            field_dict["amount"] = amount
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        game_id = d.pop("game_id")

        from_id = d.pop("from_id")

        kind = d.pop("kind")

        to_id = d.pop("to_id")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        amount = d.pop("amount", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_game_mappings_body = cls(
            game_id=game_id,
            from_id=from_id,
            kind=kind,
            to_id=to_id,
            ecosystem_id=ecosystem_id,
            amount=amount,
            sort_order=sort_order,
        )

        return post_v1_game_mappings_body
